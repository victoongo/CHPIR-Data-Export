require 'yaml'
require 'ostruct'
require 'csv'

def hashes2ostruct(object)
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = hashes2ostruct(value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| hashes2ostruct(i) }
  else
    object
  end
end

yaml_path = Dir.getwd
puts "#{yaml_path}"
yaml_files = Dir["#{yaml_path}/*.y*ml"]
if yaml_files.count > 0 
  Dir.mkdir("stata") unless Dir.exists?("stata")
  stata_path = "#{yaml_path}/stata"
  
  yaml_files.each do |yaml_file|
    current_file = yaml_file.split('/').last
    yaml_name = current_file.split('.').first
    yaml_ext = current_file.split('.').last

    survey = hashes2ostruct(YAML.load_file("#{yaml_path}/#{yaml_name}.#{yaml_ext}"))

    hash = survey["hash"]
    puts "#{hash}"

    unless File.exists?("stata/lab_#{hash}.do")

      section_number=0

      stata = []
      stata << %Q[#delimit ;]
      CSV.open("#{stata_path}/q_#{hash}.csv", 'w') do |csv| 
        header = ['section','question_order_number','variable_name','unique_id','question_identifier',
                  'question_type','question_text','response_options_number','response_options_text']
        csv << header
        survey.sections.each do |section|
          section_number+=1
          question_count=0
          
          section.questions.each do |question|
            question_count+=1
            #puts question.uniqueid
            qid = "q_#{question.uniqueid}_#{question.identifier}"
            stata << %Q[\ncapture: rename q_#{question.uniqueid} #{qid};]
            stata << %Q[capture: lab var #{qid} "#{question.question_text.original}";] 
            stata << %Q[capture: notes #{qid}: "#{question.question_text.original}";]
            stata << %Q[capture: notes #{qid}: #{question.type};]
            value_count=0
            if (question.type=="select-multiple" || question.type=="select-multiple-write-in-other") && question.response_options!=nil
              question.response_options.original.each do |val|
                stata << %Q[capture: gen #{qid}_#{value_count}=cond(strmatch(#{qid},"*- '#{value_count}'*"),1,cond(strmatch(#{qid},"*...*"),.,0));] 
                stata << %Q[capture: lab var #{qid}_#{value_count} "#{val}: #{question.question_text.original}";]
                csv << ["#{section_number}", "#{question_count}", "#{qid}", question.uniqueid, question.identifier, 
                        question.type, question.question_text.original, "#{value_count}", "#{val}"]
                value_count+=1
              end
            elsif (question.type=="select-one" || question.type=="select-one-write-in-other") && question.response_options!=nil
              stata << %Q[capture: unwrap #{qid};]
              stata << %Q[capture: destring #{qid}, replace;]
              question.response_options.original.each do |val|
                if value_count==0 
                  stata << %Q[  lab def val_#{question.uniqueid} #{value_count} "#{val}";]
                else
                  stata << %Q[  lab def val_#{question.uniqueid} #{value_count} "#{val}", add;]
                end
                csv << ["#{section_number}", "#{question_count}", "#{qid}", question.uniqueid, question.identifier, 
                        question.type, question.question_text.original, "#{value_count}", "#{val}"]
                value_count+=1
              end
              stata << %Q[capture: lab val #{qid} val_#{question.uniqueid};]
            else
              stata << %Q[capture: unwrap #{qid};]
              csv << ["#{section_number}", "#{question_count}", "#{qid}", question.uniqueid, question.identifier, 
                      question.type, question.question_text.original, "", ""]
            end
          end
          puts "  # of Q = #{question_count} \n"
        end
        stata << %Q[#delimit cr]
        path = "#{stata_path}/lab_#{hash}.do"
        File.open(path, 'w') {|f| f.write(stata.join("\n")) }
      end
    end
  end
else
  puts "This directory contains no YAML file!"
end