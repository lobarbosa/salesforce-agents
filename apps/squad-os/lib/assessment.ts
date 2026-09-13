import { prisma } from "@/lib/prisma";
import { triggerAssessment } from "@/lib/github";

// Disparar o assessment são duas coisas que precisam andar juntas: acionar o
// workflow e registrar que há um run em voo. Antes só a primeira acontecia, e
// o app ficava sem saber de nada até (e se) o resultado voltasse — o que
// transformava "rodando" e "nunca rodou" no mesmo estado na tela.
//
// Mora aqui, e não dentro de uma das rotas, porque são dois gatilhos: o botão
// "Rodar assessment agora" e o disparo automático quando a org de dev conecta
// pela primeira vez (/api/sync/conexao). Um deles marcando e o outro não seria
// pior que nenhum marcar: o card mentiria só às vezes.

// O limite de "isto já devia ter respondido" vive em lib/execucao.ts, sem
// import nenhum: este arquivo puxa o Prisma, e componente de tela que
// importasse daqui levaria o adapter do Postgres pro browser.

/** Aciona o workflow e marca o cliente como "assessment rodando".
 *
 * A ordem importa: se o disparo falhar, nada é marcado — não existe run, e
 * dizer que existe deixaria o card girando por um job que nunca nasceu.
 */
export async function dispararAssessment(clientId: string, slug: string): Promise<void> {
  await triggerAssessment(slug);

  await prisma.client.update({
    where: { id: clientId },
    data: {
      assessmentStatus: "rodando",
      assessmentIniciadoEm: new Date(),
      // O erro e a URL são da rodada anterior; mantê-los aqui faria a tela
      // mostrar a falha de ontem ao lado do run de agora.
      assessmentErro: "",
      assessmentRunUrl: "",
    },
  });
}
