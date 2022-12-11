trigger PaymentTrigger on npe01__OppPayment__c (
    before insert, after insert, 
    before update, after update, 
    before delete, after delete, 
    after undelete
) {
    new MetadataTriggerHandler().run();
}