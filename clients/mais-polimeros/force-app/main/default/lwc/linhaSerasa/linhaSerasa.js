/**
 * @description       : 
 * @author            : Ríad Nassiffe
 * @group             : 
 * @last modified on  : 11-04-2023
 * @last modified by  : José Mateus Amaral
**/
import { LightningElement, api } from 'lwc';

export default class LinhaSerasa extends LightningElement {
    @api info=[];
    @api table1=''; 
    @api table2='';
    @api table3=''; 
    @api table4=''; 
    @api table5=''; 
    @api table6=''; 
    @api table7='';
    @api table8=''; 
    @api table9=''; 
    @api table10=''; 
    @api table11=''; 
    @api table12=''; 
    @api table13=''; 
    @api table14=''; 
    @api tab1Titulo;
    @api tab2Titulo;
    @api tab3Titulo; 
    @api tab4Titulo;
    @api tab5Titulo;
    @api tab6Titulo;
    @api tab7Titulo;
    @api tab8Titulo; 
    @api tab9Titulo;
    @api tab10Titulo;
    @api tab11Titulo;
    @api tab12Titulo;
    @api tab13Titulo;
    @api tab14Titulo;
    @api title;

    /*
    renderedCallback(){
        let tableContainerInnerHTML = '';
        for( let i = 0 ; i < 14 ; i++ ){
            tableContainerInnerHTML += `
            <div 
                class="slds-col slds-size_2-of-2 titulo" 
                name="tituloTabela${i+1}"
            ></div>
            <table 
                name="tab${i+1}" 
                class="slds-table slds-table_cell-buffer tabela" aria-labelledby="element-with-table-label other-element-with-table-label" lwc:dom="manual"
            ></table>
            `;
        }
        document.getElementById('tables').innerHTML = tableContainerInnerHTML;
    }
    */

    get isFieldEmpty(){
        return this.info.length == 0 && this.tab1Titulo == null;
    }

    get isTb1(){

        var tables = [this.table1,this.table2,this.table3,this.table4,this.table5,this.table6,this.table7,this.table8,this.table9,this.table10,this.table11,this.table12,this.table13,this.table14];
        
        let titulos = [this.tab1Titulo,this.tab2Titulo,this.tab3Titulo,this.tab4Titulo,this.tab5Titulo,this.tab6Titulo,this.tab7Titulo,this.tab8Titulo,this.tab9Titulo,this.tab10Titulo,this.tab11Titulo,this.tab12Titulo,this.tab13Titulo,this.tab14Titulo];

        for( let i = 0 ; i < 14 ; i++ ){
            if(tables[i] != ''){
                this.template.querySelector('div[name=tituloTabela' + (i+1) + ']').innerHTML = titulos[i];
                this.template.querySelector('div[name=tituloTabela' + (i+1) + ']').style.display = 'initial';
                this.template.querySelector('table[name=tab' + (i+1) + ']').innerHTML = tables[i];
                this.template.querySelector('table[name=tab' + (i+1) + ']').style.display = '';
            }
        }

        return '';
    }

}