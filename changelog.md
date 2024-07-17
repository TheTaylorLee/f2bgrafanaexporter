# Changelog
- 1.0.0 Initial image released
- 1.0.1 Fix if parameter
- 1.0.2 Fix if/else parameter
- 1.1.0 Modify the process loops to only run if the databases are found and accessible.
- 1.1.1 Move get-publicip into the try block and query only one ip at a time. This will prevent polling the api after a failure and prevent duplicate entries into the database as well Which resulted in exponential repeat entries.
- 1.2.0 Add optional token parameter to allow exceeding the free api limits