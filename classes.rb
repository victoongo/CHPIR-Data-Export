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
  #belongs_to :participant_type #this should be added
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
  #serialize :response # this causes the csv output to have double container "[ ""1"" ]" 
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