Groupme_scraper
=======

Scraper and stats tool for groupme.

The command scraper takes in an ammount of time, in seconds, to pull messages from a group.  Default is 24 hours.  It stores all new messages in an SQLite database, along with any new users.  The syntax is:

scraper -f config_file [-t time]

The command configure_scrapper will prompt the user for their config file, database file, oauth token, and group name.  It will also create the 'users' and 'messages' tables.  This is to be run before running scraper.

For more information on Groupme oauth, see here: https://dev.groupme.com/tutorials/oauth
