This directory will contain application-specific files related to DB
management, that will be copied from their source folders in each
application's project folder.

The purpose of copying all files here is that we can build standalone
DB management GUIs using Ocra (see tasks/db.rake, lib/packager.rb and
lib/gui/*), where the contents of this directory is included in the
resultant exe file.
