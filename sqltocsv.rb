require 'sqlite3'
require 'active_record'
require 'csv'

class Project < ActiveRecord::Base
  has_many :user_projects
  has_many :users, :through => :user_projects
  has_many :participants
  has_many :participant_types
  has_many :instruments
  has_many :instrument_versions, :through => :instruments
  has_many :interviewers
  has_many :rounds
end
class Instrument < ActiveRecord::Base
  has_many :instrument_versions, dependent: :destroy
  belongs_to :project
end
class InstrumentVersion < ActiveRecord::Base
  has_many :surveys
  has_many :data_entries, :through => :surveys
  has_many :responses, :through => :data_entries
  belongs_to :instrument
  belongs_to :project
end
class Survey < ActiveRecord::Base
  has_many :responses, :through => :data_entries
  belongs_to :participant
  belongs_to :participant_type
  belongs_to :instrument_version
  belongs_to :round
  has_many :data_entries, dependent: :destroy
end
class DataEntry < ActiveRecord::Base
  belongs_to :round
  belongs_to :survey
  belongs_to :interviewer
  has_many :responses, dependent: :destroy
end
class Response < ActiveRecord::Base
  belongs_to :data_entry
end
class Participant < ActiveRecord::Base
  has_many :surveys, dependent: :destroy
  belongs_to :project
  belongs_to :participant_type

  has_many :participants_in_rounds, dependent: :destroy
  has_many :rounds, :through => :participants_in_rounds

  has_many :participant_relationships, dependent: :destroy
  has_many :relationships, :through => :participant_relationships

  has_many :participant_attributes, dependent: :destroy
  accepts_nested_attributes_for :participant_attributes
end
class ParticipantType < ActiveRecord::Base
  has_many :participants
  has_many :attribute_types, dependent: :destroy
  belongs_to :project
end
class ParticipantsInRound < ActiveRecord::Base
  belongs_to :participant
  belongs_to :round
end
class RelationshipType < ActiveRecord::Base
end
class Relationship < ActiveRecord::Base
  has_many :participant_relationships
  has_many :participants, :through => :participant_relationships
  belongs_to :relationship_type
end
class ParticipantRelationship < ActiveRecord::Base
  belongs_to :participant
  belongs_to :relationship
  has_one :relationship_type, through: :relationship
end
class AttributeType < ActiveRecord::Base
  belongs_to :participant_type
end
class ParticipantAttribute < ActiveRecord::Base
  belongs_to :participant
  belongs_to :attribute_type
end
class Round < ActiveRecord::Base
  has_many :participants_in_rounds
  has_many :participants, :through => :participants_in_rounds
  has_many :surveys
  has_many :data_entries
  belongs_to :project
end
class User < ActiveRecord::Base
  has_many :user_projects
  has_many :projects, :through => :user_projects
end
class Interviewer < ActiveRecord::Base
  has_many :surveys
  has_many :data_entries
  belongs_to :project
end

header = ['__project_name', '__instrument_name', '__instrument_version_name', 
  '__round_name', '__tracking_number', '__date_of_interview', 
  '__user_id', '__interviewer_name', '__entry_type', '__entry_id', '__created_at', '__updated_at',
  '__participant_id', '__participant_type', '__participant_attribute_id', '_study_id',
  '__relationship_id', 
  "unique_id", "response", "special", "other", "edituser", "edittime"]

# dir_lst = [
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_1/csv",
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_2/csv", 
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_4/csv",
 # "/home/victor/share/POFO/Data/raw/r8/Duke_USB_5/csv",
 # "/home/victor/share/FCIC/CFAR_Ethiopia/Data/raw"
#  ]
sql_path = Dir.getwd
puts "#{sql_path}"
dir_lst = ["#{sql_path}"]

for i in dir_lst
  #sqlite_files = Dir["#{i}/*.sqlite3"]
  sqlite_files = Dir["#{i}/data_entry.sqlite3"]
  if sqlite_files.count > 0 
    sqlite_files.each do |sqlite_file|
      puts "\n---------- Exporting Database ---------- #{sqlite_file}"
      current_file = sqlite_file.split('/').last
      sqlite_name = current_file.split('.').first
      #Dir.mkdir("#{sqlite_name}_csv") unless Dir.exists?("#{sqlite_name}_csv")
      Dir.mkdir("csv") unless Dir.exists?("csv")

      ActiveRecord::Base.establish_connection(
        :adapter  => 'sqlite3',
        :database => "#{i}/data_entry.sqlite3")
      #csv_path = "#{i}/#{sqlite_name}_csv"
      csv_path = "#{i}/csv"
      InstrumentVersion.find_each do |instrument_version| 
        if instrument_version.instrument && instrument_version.surveys.any?
          puts "#{instrument_version.version_hash}-------exporting to csv"
          CSV.open("#{csv_path}/new_#{instrument_version.version_hash}.csv", 'w') do |csv|
            csv << header
            instrument_version.surveys.each do |survey|
              if survey.participant && survey.participant.participant_relationships
                _relationship_id = []
                survey.participant.participant_relationships.find_each do |participant_relationship|
                  _relationship_id.push(participant_relationship.relationship_id)
                end
                _participant_attribute_id = []
                _study_id = []
                survey.participant.participant_attributes.find_each do |participant_attribute|
                  _participant_attribute_id.push(participant_attribute.id)
                  _study_id.push(participant_attribute.id)
                end
                survey.data_entries.each do |data_entry|
                  data_entry.responses.each do |response|
                    row = [instrument_version.instrument.project.name, instrument_version.instrument.name, instrument_version.version_name, 
                        survey.round.name, survey.tracking_number, survey.date_collected, 
                        data_entry.user_id, data_entry.interviewer.name, data_entry.entry_type, data_entry.id, data_entry.created_at, data_entry.updated_at, 
                        survey.participant_id, survey.participant.participant_type.name, "#{_participant_attribute_id}", "#{_study_id}", 
                        "#{_relationship_id}"]  
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
  else
    puts "This directory contains no sqlite3 files!"
  end
end
