# Deploy na sandbox de QA

- **Org:** `sbx-eplast-qa`
- **Deploy:** `0AfHa00000EJKsbKAH` (Succeeded)
- **Quando:** 2026-11-17T14:27Z
- **Commit:** `ebbccee3`

## Trabalhos agendados cancelados antes do deploy

A plataforma recusa atualizar classe com trabalho pendente. Estes trabalhos das classes do pacote, deixados por rodada anterior, foram cancelados na sandbox de QA e **não foram rearmados**: o teste arma de novo o que precisar.

- 08eHa00000Xr4SZ EPLAST33 Sinais Comerciais, agenda 0 0 1 * * ?, estado WAITING
- 707Ha00001E4RF1 sem agenda registrada (trabalho assíncrono em andamento)

## Componentes
- `force-app/main/default/classes/CommercialSignalBatch.cls`
- `force-app/main/default/classes/CommercialSignalBatch.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalBatchTest.cls`
- `force-app/main/default/classes/CommercialSignalBatchTest.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalGroupStatsBatch.cls`
- `force-app/main/default/classes/CommercialSignalGroupStatsBatch.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalGroupStatsBatchTest.cls`
- `force-app/main/default/classes/CommercialSignalGroupStatsBatchTest.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalScheduler.cls`
- `force-app/main/default/classes/CommercialSignalScheduler.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalSchedulerTest.cls`
- `force-app/main/default/classes/CommercialSignalSchedulerTest.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalService.cls`
- `force-app/main/default/classes/CommercialSignalService.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalServiceTest.cls`
- `force-app/main/default/classes/CommercialSignalServiceTest.cls-meta.xml`
- `force-app/main/default/classes/CommercialSignalTestFactory.cls`
- `force-app/main/default/classes/CommercialSignalTestFactory.cls-meta.xml`
- `force-app/main/default/customMetadata/CommercialSignalSetting.Default.md-meta.xml`
- `force-app/main/default/groups/EPLAST33_SinaisComerciais.group-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/CommercialSignalSetting__mdt.object-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/BatchSize__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellExcludedFamilies__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellGroupField__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellLevel__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellLookbackMonths__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellMaxPerAccount__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellMinGroupSize__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellMinSharePercent__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/CrossSellRecentDays__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/FamilyField__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/IncludeNeverPurchased__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/PurchaseDateField__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/PurchaseStatuses__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/RecoveryDays__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/VolumeDirections__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/VolumeMetric__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/VolumeMinBaseMonths__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/VolumeThresholdPercent__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignalSetting__mdt/fields/VolumeWindowMonths__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/CommercialSignal__c.object-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/Account__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/BasePeriodAmount__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/BasePeriodQuantity__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/CalculationDate__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/CurrentPeriodAmount__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/CurrentPeriodQuantity__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/DaysWithoutPurchase__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/LastPurchaseDate__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/ProductFamily__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/Product__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/Reason__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/SignalKey__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/Type__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/UnitOfMeasure__c.field-meta.xml`
- `force-app/main/default/objects/CommercialSignal__c/fields/VariationPercent__c.field-meta.xml`
- `force-app/main/default/permissionsets/PS_Comercial_SinaisComerciais.permissionset-meta.xml`
- `force-app/main/default/reportTypes/Accounts_with_CommercialSignals.reportType-meta.xml`
- `force-app/main/default/reports/EPLAST33_SinaisComerciais.reportFolder-meta.xml`
- `force-app/main/default/reports/EPLAST33_SinaisComerciais/CommercialSignals_ByAccount.report-meta.xml`
- `force-app/main/default/tabs/CommercialSignal__c.tab-meta.xml`
