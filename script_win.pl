#! usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Spec;

#init
my $file_list = "/.module_script/filelist.txt";
my $purge_list = "/.module_script/purgelist.txt";
my $choice = "";
my $ext_path = "";
my $mage_path = "";
my $temp_ext_path = "";
my $temp_mage_path = "";
my $directories = "";
# my $temp_ext_path = "C:\\Users\\LabRat1\\Desktop\\scripttest";#hardcoded path REMOVE LATER
# my $temp_mage_path = "D:\\projects\\Netbeans test\\magento";#hardcoded path REMOVE LATER

sub createPath {
	# function that converts all file and folder names containing whitespace to same name with quotation
	(my $temp_path) = @_;
	my @split = File::Spec->splitdir( $temp_path );
	my $arr_count = @split;
	my $path = "";
	for (my $x = 0; $x <= $arr_count - 1; $x++){
		if ( $split[$x] =~ m/^\w+\s+\w+$/){
			$split[$x] =~ s /$split[$x]/"$split[$x]"/; # if there is a path with whitespace replace it with "path"
			$path = $path.$split[$x]."\\";
		}
		else{ $path = $path.$split[$x]."\\"; }
		
	}
	if ( $temp_path eq $temp_mage_path){ $mage_path = $path; } # checks if this is path to extension or to magento
	elsif ($temp_path eq $temp_ext_path){ $ext_path = $path; }
}

print "Running script!\n";
print "What would you like to do?\n 1. Add your symlinks to Magento.\n 2. Remove your symlinks.\n 3. Quit.\n";
print "Please pick an option and enter it's number: ";
chomp ($choice = <>); # get options input and check if is valid
print "Your choice: ".$choice."\n";
#if quit or different than other options symbol is selected - die
unless (($choice =~ m/^1$/) || ($choice =~ m/^2$/)) { die "Your choice was to exit or invalid option! Exiting!\n"; }

print "Enter the path to your extension (example C:\\Users\\MyUser\\Magento_Extension): ";
chomp ($temp_ext_path = <>); # get extension path from input
createPath($temp_ext_path);

print "Enter the path to your Magento installation (example C:\\Projects\\Magento): ";
chomp ($temp_mage_path = <>); # get magento path
createPath($temp_mage_path);

print "Extension path: ".$ext_path."\n";
print "Magento path: ".$mage_path."\n";

unless (-d $ext_path."\\.module_script"){
	# initial check for the script system folder. If this is first run will create the folder 
	# and the files and the script will die
	print "Creating script folder and files!\n";
	my $script_dir = $ext_path.".module_script";
	print $script_dir;
	system ("md ".$script_dir."\n"); # creates the .module_script folder
	my $cmd = "echo "."# Add the path to the files that will be added. Enter the path from extension folder (ex \\skin\\frontend\\mytheme)"." > ".$script_dir."\\filelist.txt"."\n";
	print "Creating filelist.txt".$cmd."\n";
	system ($cmd); # creates filelist.txt
	$cmd = "echo "."# Do not edit or delete! This file tracks links created by the script in order to remove them later"." > ".$script_dir."\\purgelist.txt\n";
	print "Creating purgelist.txt".$cmd."\n";
	system ($cmd); # creates purgelist.txt
	die ("Exiting! Rerun when done adding items to the filelist.txt\n");
}
else { print "Deleting all symlinks!\n"; } # if the system folder exist proceed to execution

open(FILE, $ext_path.$purge_list) or die("Unable to open file!"); # Open purge list. Everyting in the list will be deleted after confirmation
my @purge = <FILE>;
close (FILE);

foreach my $item (@purge) {
	chomp ($item);
	our($filename, $directories, $suffix) = fileparse($item); # parses each path to directories and file names
	sub createDelPath {
	# similar to createPath function but used for deleteing the symlinks
		(my $temp_path) = @_;
		my @split = File::Spec->splitdir( $temp_path ); # splits parsed dirs to single folder names
		my $arr_count = @split;
		my $path = "";
		for (my $x = 0; $x <= $arr_count - 1; $x++){
			if ( $split[$x] =~ m/^\w+\s+\w+$/){
				$split[$x] =~ s/$split[$x]/"$split[$x]"/; # if there is a path with whitespace replace it with "path"
				$path = $path.$split[$x]."\\";
			}
			else{ $path = $path.$split[$x]."\\"; }
		}
		if ($temp_path eq $directories.$filename){ $directories = $path; } # checks if processed path is same as parsed
		else { print "Something went wrong\n"; } # if this is not true - error
	}
	print "Checking for exiting file ($item). \n";
	if ((-e $item) && (-f $item)) { # checks if the line of the purge list is existing item and is file
		createDelPath($directories.$filename);
		$directories =~ s/\\$//g;
		my $delete = "del /p ".$directories."\n";
		print $delete;
		system($delete);
	}
	else {
		# if this line don't contains path for file - check for existing directories and deletes them
		print "File don't exist. "."Checking for directories.\n";
		if(-d $directories.$filename) {
			createDelPath($directories.$filename);
			my $delete = "rd ".$directories."\n";
			print "Deleting $directories! Are you sure? y/n: ";
			my $confirm = <>;
			if ($confirm =~ m/y/) { system($delete); } # added as input for security reasons - user confirmation to delete tree
			else { print "Deleting canceled!"."\n"; }
		}
		else { print "Can't find this file\n"; } # error if file/dir not found
	}
}
if ($choice =~ m/^2$/) {
	my $clr_purgelist = "echo "."# Do not edit or delete! This file tracks links created by the script in order to remove them later > ".$ext_path.$purge_list."\n";
	system ($clr_purgelist);
	die "Delete finished! Exiting!\n"; # if remove links option is chosen - exit after deleting, else continues execution
} 

open(FILE, $ext_path.$file_list) or die("Unable to open file!"); # Open file list
my @folders = <FILE>;
close (FILE);

foreach my $line (@folders) {
	chomp ($line);
	unless ($line =~ m/^#/){
		my($filename, $directories, $suffix) = fileparse($line);# Parse each line of the file to path and file name
		if ((-d $temp_mage_path."\\".$directories) && (-f $temp_ext_path.$directories.$filename)){ 
			print $temp_mage_path."\\".$directories." - Directory exists!\n";# Check for dir
			if (-e $temp_mage_path.$directories.$filename) { 
				print $temp_mage_path.$directories.$filename." - File already exists!\n";# Check for file
			} 
			else {
				print "Creating file: ".$filename."\n";
				my $mklink_file = "mklink ".$mage_path.$directories.$filename."\ ".$ext_path.$directories.$filename."\n";#Creates file symlink
				system($mklink_file);#TBD change to exec
			}
		} 
		else {
			# print "Directories: ".$directories."\n";
			my @splitdir = File::Spec->splitdir( $directories.$filename );#splits path to dir
			my @onlydir = map {$_ ? $_ : ()} @splitdir;#removes all empty array items
			my $size = @onlydir;#get array size
			my $scope = "";#initialize $scope
			for (my $i = 0; $i <= $size -1; $i++){
				$scope = $scope.$onlydir[$i]."\\";
				if (-d $temp_mage_path."\\".$scope) { print $temp_mage_path.$scope." - Directory already exists!\n"; } #Check for dir
				else {
					print "Creating directory: "."\n";
					my $mklink_folder = "mklink /d ".$mage_path.$scope." ".$ext_path.$scope."\n";#uses only the highest dir for symlink
					print $mklink_folder."\n";
					system($mklink_folder);#TBD change to exec
				}
			}
		}
	}
	else { print "Disabled or invalid path was found in filelist.txt\n" };
}

my $create_purgelist = "dir ".$mage_path." /a:l /s /b > ".$ext_path.$purge_list;#search magento for symlinks and add them to file to be removed
system($create_purgelist);#TBD change to exec
print "Done!\n";