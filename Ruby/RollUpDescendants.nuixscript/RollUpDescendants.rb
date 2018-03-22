# Menu Title: Roll Up Descendants
# Needs Case: true
# Needs Selected Items: true

# Bootstrap Nx library
script_directory = File.dirname(__FILE__)
require File.join(script_directory,"Nx.jar")
java_import "com.nuix.nx.NuixConnection"
java_import "com.nuix.nx.LookAndFeelHelper"
java_import "com.nuix.nx.dialogs.ChoiceDialog"
java_import "com.nuix.nx.dialogs.TabbedCustomDialog"
java_import "com.nuix.nx.dialogs.CommonDialogs"
java_import "com.nuix.nx.dialogs.ProgressDialog"
java_import "com.nuix.nx.digest.DigestHelper"
java_import "com.nuix.nx.controls.models.Choice"

LookAndFeelHelper.setWindowsIfMetal
NuixConnection.setUtilities($utilities)
NuixConnection.setCurrentNuixVersion(NUIX_VERSION)

# Make sure script wasn't somehow executed without items selected
if $current_selected_items.nil? || $current_selected_items.size < 1
	CommonDialogs.showWarning("This script requires items be selected before running it!")
	exit 1
end

require 'csv'

# Build our settings dialog
dialog = TabbedCustomDialog.new("Roll Up Descendants")

main_tab = dialog.addTab("main_tab","Main")
main_tab.appendHeader("Selected Items: #{$current_selected_items.size}")
main_tab.appendTextField("text_separator","Text Separator","\\n\\n")
main_tab.appendCheckBox("skip_whitespace_descendants","Don't Append Empty Text from Descendants",true)
main_tab.appendCheckBox("only_immaterial_children_and_descendants","Only Roll Up Immaterial Children and Their Descendants",true)
main_tab.appendCheckBox("backup_text","Backup Selected Item Text",false)
main_tab.appendDirectoryChooser("backup_text_directory","Text Backup Directory")
default_backup_directory = File.join($current_case.getLocation.getPath,"Text Backup",Time.now.strftime("%Y-%m-%d_%H-%M-%S"))
default_backup_directory = default_backup_directory.gsub("/","\\")
main_tab.setText("backup_text_directory",default_backup_directory)
main_tab.enabledOnlyWhenChecked("backup_text_directory","backup_text")

# Settings for how to handle rolled up items
main_tab.appendRadioButton("exclude_rolled_up_items","Exclude Rolled Up Descendants","rollup_handling_group",true)
main_tab.appendTextField("roll_up_exclusion","Exclusion Name","Rolled Up Descendants")
main_tab.enabledOnlyWhenChecked("roll_up_exclusion","exclude_rolled_up_items")

main_tab.appendRadioButton("tag_rolled_up_items","Tag Rolled Up Descendants","rollup_handling_group",false)
main_tab.appendTextField("roll_up_tag","Tag Name","Rolled Up Descendants")
main_tab.enabledOnlyWhenChecked("roll_up_tag","tag_rolled_up_items")

main_tab.appendRadioButton("delete_rolled_up_items","Delete Rolled Up Descendants","rollup_handling_group",false)

# Settings dialog validations
dialog.validateBeforeClosing do |values|
	# Get user confirmation about closing all workbench tabs
	if CommonDialogs.getConfirmation("The script needs to close all workbench tabs, proceed?") == false
		next false
	end

	# Everything looks good, yield true to signal this
	next true
end

# Display the settings dialog
dialog.display

# If user clicked okay lets get to work
if dialog.getDialogResult == true
	# Obtain settings as hash/map
	values = dialog.toMap

	# Store settings in variables for convenience
	text_separator = values["text_separator"].gsub("\\n","\n").gsub("\\t","\t").gsub("\\r","\r")
	skip_whitespace_descendants = values["skip_whitespace_descendants"]
	backup_text = values["backup_text"]
	backup_text_directory = values["backup_text_directory"]
	exclude_rolled_up_items = values["exclude_rolled_up_items"]
	roll_up_exclusion = values["roll_up_exclusion"]
	tag_rolled_up_items = values["tag_rolled_up_items"]
	roll_up_tag = values["roll_up_tag"]
	delete_rolled_up_items = values["delete_rolled_up_items"]
	only_immaterial_children_and_descendants = values["only_immaterial_children_and_descendants"]

	# If prior to Nuix 6.2.9 we need to convert selected items to an array
	# so that ItemSorter.sortItemsByPosition can sort them
	items = nil
	if NuixConnection.getCurrentNuixVersion.isLessThan("6.2.9")
		items = $current_selected_items.to_a
	else
		items = $current_selected_items
	end
	items = $utilities.getItemSorter.sortItemsByPosition(items)
	
	$window.closeAllTabs

	ProgressDialog.forBlock do |pd|
		pd.setTitle("Roll Up Descendants")
		pd.logMessage("Text Separator: #{text_separator.gsub("\n","\\n").gsub("\r","\\r").gsub("\t","\\t")}")
		pd.logMessage("Don't Append Empty Text from Descendants: #{skip_whitespace_descendants}")
		pd.logMessage("Only Roll Up Immaterial Children and Their Descendants: #{only_immaterial_children_and_descendants}")
		pd.logMessage("Backup Text: #{backup_text}")
		if backup_text
			pd.logMessage("Text Backup Directory: #{backup_text_directory}")
		end

		# Determine and log how we're handling the rolled up items
		descendant_handling = ""
		descendant_handling_secondary = nil
		if exclude_rolled_up_items
			descendant_handling = "Excluded"
			descendant_handling_secondary = "Exclusion Name: #{roll_up_exclusion}"
		elsif tag_rolled_up_items
			descendant_handling = "Tagged"
			descendant_handling_secondary = "Tag Name: #{roll_up_tag}" 
		elsif delete_rolled_up_items
			descendant_handling = "Deleted"
		end

		pd.logMessage("After roll up descendants will be: #{descendant_handling}")
		if !descendant_handling_secondary.nil?
			pd.logMessage(descendant_handling_secondary)
		end

		pd.logMessage("Selected Items: #{items.size}")
		pd.setMainStatusAndLogIt("Filtering out items which have no descendants...")
		items = items.select{|item| $current_case.count("path-guid:#{item.guid}") > 0}
		pd.logMessage("Items With Descendants: #{items.size}")

		# Are we backing up text first?
		if backup_text
			pd.setMainStatusAndLogIt("Backing up item text...")
			java.io.File.new(backup_text_directory).mkdirs

			CSV.open(File.join(backup_text_directory,"BackupListing.csv"),"w:utf-8") do |csv|
				csv << [
					"GUID",
					"Relative Path",
				]

				pd.setMainProgress(0,items.size)

				items.each_with_index do |item,item_index|
					break if pd.abortWasRequested
					pd.setMainProgress(item_index+1)
					pd.setSubStatus("#{item_index+1}/#{items.size}")
					guid = item.getGuid
					item_text = item.getTextObject.toString
					item_text_path = File.join(backup_text_directory,guid[0..2],guid[3..5],"#{guid}.txt")
					java.io.File.new(item_text_path).getParentFile.mkdirs
					File.open(item_text_path,"w:utf-8") do |text_file|
						text_file.puts item_text
					end
					item_text = nil
					csv << [
						guid,
						"#{guid[0..2]}\\#{guid[3..5]}\\#{guid}.txt",
					]
				end
			end
		end

		already_processed = {}
		annotater = $utilities.getBulkAnnotater
		iutil = $utilities.getItemUtility

		# Begin roll up
		pd.setMainStatusAndLogIt("Rolling Up Descendants")
		$current_case.withWriteAccess do
			pd.setMainProgress(0,items.size)
			items.each_with_index do |item,item_index|
				break if pd.abortWasRequested
				pd.setMainProgress(item_index+1)
				pd.setMainStatus("Rolling Up Descendants #{item_index+1}/#{items.size}")
				if already_processed[item]
					pd.logMessage("Skipping item already previously rolled up: #{item.getLocalisedName} - #{item.getGuid}")
				else 
					already_processed[item] = true
					descendants = nil
					if only_immaterial_children_and_descendants
						immaterial_children = item.getChildren.reject{|child| child.isAudited}
						descendants = iutil.findItemsAndDescendants(immaterial_children)
						if descendants.size < 1
							pd.logMessage("Skipping item with no immaterial children: #{item.getLocalisedName} - #{item.getGuid}")
						end
					else
						descendants = item.getDescendants
					end

					item_text_object = item.getTextObject

					item_text = []
					item_text << item_text_object.toString

					pd.setSubProgress(0,descendants.size)
					descendants.each_with_index do |descendant_item,descendant_index|
						pd.setSubProgress(descendant_index+1)
						pd.setSubStatus("#{descendant_index+1}/#{descendants.size}")
						already_processed[descendant_item] = true
						descendant_text = descendant_item.getTextObject.toString || ""
						if skip_whitespace_descendants && descendant_text.strip.empty?
							next
						end
						item_text << descendant_text
					end
					
					item_text = item_text.join(text_separator)
					item.modify do |item_modifier|
						item_modifier.replaceText(item_text)
					end

					# If there is file system stored text, then lets update it
					if item_text_object.isStored
						stored_path_object = item_text_object.getStoredPath
						if !stored_path_object.nil?
							stored_path = stored_path_object.toString
							File.open(stored_path,"w:utf-8") do |file|
								file.puts(item_text)
							end
						end
					end

					# Do something with the descendants
					if !pd.abortWasRequested
						if exclude_rolled_up_items
							annotater.exclude(roll_up_exclusion,descendants)
						elsif tag_rolled_up_items
							annotater.addTag(roll_up_tag,descendants)
						elsif delete_rolled_up_items
							item.getChildren.each do |child_item|
								child_item.removeItemAndDescendants
							end
						end
					end
				end
			end
		end

		$window.openTab("workbench",{:search=>""})

		if !pd.abortWasRequested
			pd.setCompleted
		else
			pd.logMessage("User Aborted")
		end
	end
end