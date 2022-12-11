// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

String strName = Global_GL_Account__mdt.getInstance(
    Fundraising_Subledger_Setting__mdt.getInstance('Default').Default_Payment_Account__c
).GL_Account_Name__c;
System.debug('::::: acc name : ' + strName);