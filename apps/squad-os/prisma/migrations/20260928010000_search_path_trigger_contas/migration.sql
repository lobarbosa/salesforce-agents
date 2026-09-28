-- Linter do Supabase (0011_function_search_path_mutable): função sem search_path
-- fixo herda o do chamador. A função só lança exceção e não referencia objeto
-- nenhum, então search_path vazio é seguro e fecha o aviso.
ALTER FUNCTION contas_pagar_eventos_imutavel() SET search_path = '';
