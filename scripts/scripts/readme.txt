in this project all advanced features implemented like 

1. dynmic seeder for generating fake data for any model
2. Custom commands for greet users,sendEmailRemainder, Show current date time
3. DTO for standerd 
4. Service Repository Pattern, Interfaces
5. shell script to automate all work like create scalaton for entire module like Post Module 
   by running just one line command that will install and create all required file or directory structure for complete module
   
   : chmod +x ./scripts/generate-module.sh  ## run this if you made some changes in script
   : ./scripts/generate-module.sh Post   ## run this for creating entire module 

6. shell scripts for make backup and restore backup 
   : ./scripts/backup-db.sh
   : ./scripts/restore-db.sh
7. After makeing changes seed dynamic models dommy data by running this command 
   : php artisan migrate:fresh --seed   

