Groupme_scraper
=======

Scraper and stats tool for groupme.

The command scraper takes in an ammount of time, in seconds, to pull messages from a group.  By default, it will pull all messages in a group, unless a time is presented via a -t argument (where t is time, in seconds).  It stores all new messages in an SQLite database, along with any new users.  The syntax is:

scraper -f config_file [-t time]

Scraper uses a sqlite3 database with three tables:

**users**

Name(TEXT) - Name of the user, when first added
Uid(INT) - Unique Groupme user id

**messages**
id(INT) - Unique groupme message id
created_at(INT) - Time, in seconds from epoch, of message cretion
user_id(INT) - Unique Groupme user id
text(TEXT) - Message text
image(TEXT) - Image url.  'None' if there was no attachment

**likes**
message_id(INT) - Unique groupme message id
user_id(INT) - Unique Groupme user id

The command configure_scrapper will prompt the user for their config file, database file, oauth token, and group name.  It will also create the sqlite3 tables.  This is to be run before running scraper for the first time.

For more information on Groupme oauth, see here: https://dev.groupme.com/tutorials/oauth
