require 'sqlite3'
require 'active_record'
require 'csv'
require './classes.rb'
header = ['__project_name', '__instrument_name', '__instrument_version_name', 
  '__round_name', '__tracking_number', 
  '__user_id', '__interviewer_name', '__entry_type', '__entry_id', '__created_at', '__updated_at',
  '__participant_id', '__participant_type', '__relationship_id', '__participant_attribute_id',   
  "unique_id", "response", "special", "other", "edituser", "edittime"]
dir_lst = [
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_1/csv",
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_2/csv", 
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_4/csv",
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_5/csv",
  "/home/victor/share/FCIC/CFAR_Ethiopia/Data/raw"
  ]
for i in dir_lst
  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    :database => "#{i}/data_entry.sqlite3")
  csv_path = "#{i}"
  InstrumentVersion.find_each do |instrument_version| #production
  #InstrumentVersion.find("id=91") do |instrument_version| #testing
    if instrument_version.instrument && instrument_version.surveys.any?
      puts "#{instrument_version.version_hash}-------good to go"
      CSV.open("#{csv_path}/#{instrument_version.version_hash}.csv", 'w') do |csv|
        csv << header
        instrument_version.surveys.each do |survey|
          if survey.participant && survey.participant.participant_relationships
            #*_relationship_type_name = []
            _relationship_id = []
            survey.participant.participant_relationships.find_each do |participant_relationship|
              #*_relationship_type_name.push(participant_relationship.relationship.relationship_type.name) # this cause compond double quote problem
              _relationship_id.push(participant_relationship.relationship_id)
              #should output the relationship_id and relationship_type.name to parse the array
            end
            #*_attribute_type_name = []
            #_participant_attribute_value = []
            _participant_attribute_id = []
            survey.participant.participant_attributes.find_each do |participant_attribute|
              #*_attribute_type_name.push(participant_attribute.attribute_type.name) # this cause compond double quote problem
              _participant_attribute_id.push(participant_attribute.id)
              #_participant_attribute_value.push(participant_attribute.value)
              #should output the relationship_id and relationship_type.name to parse the array
            end
            survey.data_entries.each do |data_entry|
              data_entry.responses.each do |response|
                row = [instrument_version.instrument.project.name, instrument_version.instrument.name, instrument_version.version_name, 
                    survey.round.name, survey.tracking_number, 
                    data_entry.user_id, data_entry.interviewer.name, data_entry.entry_type, data_entry.id, data_entry.created_at, data_entry.updated_at, 
                    survey.participant_id, survey.participant.participant_type.name, "#{_relationship_id}", "#{_participant_attribute_id}"] #"#{_relationship_type_name}", 
                row.push(response.uniqueid, response.response, response.special_response,
                    response.other_response, response.user_id, response.updated_at)
                csv << row
              end
            end
          end
        end
      end
    else 
      puts "#{instrument_version.version_hash}"
    end
  end
end
