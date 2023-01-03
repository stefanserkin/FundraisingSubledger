// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

// Schedule accounting job
// fsl_AccountingJobScheduler.run();
// fsl_FutureAllocationsScheduler.run();

Contact ct = new Contact();
ct.FirstName = 'Johan';
ct.LastName = 'Santana';
ct.Email = 'johanono@yahoo.com';
ct.Phone = '646-701-2012';
insert ct;
