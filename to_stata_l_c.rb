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

dir_lst = [
	# "/home/victor/share/POFO/Data/raw/r8", 
	 "/home/victor/share/FCIC/CFAR_Ethiopia/Data/raw"
	]

for i in dir_lst
	stata_paths = "#{i}/code/do"

	yaml_paths = "#{i}/yaml"
	#yaml_files = Dir["#{yaml_paths}/c8d9c08466d53c310868d557fa545ba7dd918feb.yml"]
	yaml_files = Dir["#{yaml_paths}/*.y*ml"]

	hash_list = []
	#hash_list << %Q[clear all]
	##hash_list << %Q[do "../do/programs.do"]
	#hash_list << %Q[set more off]
	#hash_list << %Q[set matsize 11000]
	#hash_list << %Q[set maxvar 32767]

	yaml_files.each do |yaml_file|
	  current_file = yaml_file.split('/').last
	  yaml_name = current_file.split('.').first


		if File.file?("#{yaml_paths}/#{yaml_name}.yml")
		survey = hashes2ostruct(YAML.load_file("#{yaml_paths}/#{yaml_name}.yml"))
		else
		survey = hashes2ostruct(YAML.load_file("#{yaml_paths}/#{yaml_name}.yaml"))
		end

		hash = survey["hash"]
		#puts "#{survey}"
	  puts "#{hash}"

		hash_list << %Q[clear all]
		hash_list << %Q[local hash : dir .  files  "#{hash}.csv", respectcase]
		hash_list << %Q[di `"`hash'"']
		#hash_list << %Q[insheet using "#{hash}.csv"]
		hash_list << %Q[if `"`hash'"'~="" insheet using "#{hash}.csv"]
		hash_list << %Q[if _N>0 do "../../code/do/lab_#{hash}.do"]

		section_number=0

		stata = []
		##stata << %Q[clear all]
		##stata << %Q[insheet using "#{survey["hash"]}.csv"]
		##stata << %Q[if _N>0 {]
		#stata << %Q[reshape wide response identifier special other edituser edittime, i(__entry_id) j(unique_id)]
		#stata << %Q[rename response* q_*]
		#stata << %Q[rename identifier* q_*_identifier]
		#stata << %Q[rename special* q_*_special]
		#stata << %Q[rename other* q_*_other]
		#stata << %Q[rename edituser* q_*_edituser]
		#stata << %Q[rename edittime* q_*_edittime]
		#stata << %Q[compress]
		stata << %Q[#delimit ;]
		CSV.open("#{stata_paths}/q_#{hash}.csv", 'w') do |csv| 
			#q_list = []
			header = ['section','question_order_number','variable_name','unique_id','question_identifier',
								'question_type','question_text','response_options_number','response_options_text']
			csv << header
			survey.sections.each do |section|
				section_number+=1
				question_count=0
				
			  section.questions.each do |question|
			  	#question_text = question["question_text"]["original"]
			  	#question_text = "#{question["question_text"]["original"]}"
			  	#question["question_text"]["original"].gsub(";", "")
			  	#question_text.gsub(";", ",")
			  	#puts "#{question_text}"
			  	question_count+=1
			  	puts question.uniqueid
			  	qid = "q_#{question.uniqueid}_#{question.identifier}"
			  	stata << %Q[\ncapture: rename q_#{question.uniqueid} #{qid};]

			    stata << %Q[capture: lab var #{qid} "#{question.question_text.original}";] 
			    #stata << %Q[capture: notes #{qid}: #{question["identifier"]}: "#{question_text}";\n]
			    stata << %Q[capture: notes #{qid}: "#{question.question_text.original}";]
			    stata << %Q[capture: notes #{qid}: #{question.type};]
			    #row = [section, "#{qid}", question.uniqueid, question.identifier, question.type]
			    value_count=0
			    # just need to loop through the values here
			    if (question.type=="select-multiple" || question.type=="select-multiple-write-in-other") && question.response_options!=nil
			    	question.response_options.original.each do |val|
			        stata << %Q[capture: gen #{qid}_#{value_count}=cond(strmatch(#{qid},"*- '#{value_count}'*"),1,cond(strmatch(#{qid},"*...*"),.,0));] 
			        	# still need to deal with missing
			        stata << %Q[capture: lab var #{qid}_#{value_count} "#{val}: #{question.question_text.original}";]
			        #stata << %Q[capture: replace #{qid}_#{value_count}=1 if strmatch(#{qid},"*- '#{value_count}'*");]
			        #stata << %Q[capture: replace #{qid}_#{value_count}=1 if strmatch(#{qid},"*- '#{value_count}'*");]
			        csv << ["#{section_number}", "#{question_count}", "#{qid}", question.uniqueid, question.identifier, 
			        				question.type, question.question_text.original, "#{value_count}", "#{val}"]
			        #q_list << row
			        value_count+=1
			      end
			    elsif (question.type=="select-one" || question.type=="select-one-write-in-other") && question.response_options!=nil
			    #elsif question["response_options"]
			      stata << %Q[capture: unwrap #{qid};]
			      stata << %Q[capture: destring #{qid}, replace;]
			      question.response_options.original.each do |val|
			        if value_count==0 
			          stata << %Q[  lab def val_#{question.uniqueid} #{value_count} "#{val}";]
			          #n=n+1
			        else
			          stata << %Q[  lab def val_#{question.uniqueid} #{value_count} "#{val}", add;]
			          #n=n+1
			        end
			        csv << ["#{section_number}", "#{question_count}", "#{qid}", question.uniqueid, question.identifier, 
			        				question.type, question.question_text.original, "#{value_count}", "#{val}"]
			        #q_list << row
			        value_count+=1
			      end
			    	stata << %Q[capture: lab val #{qid} val_#{question.uniqueid};]
			  	else
			  		stata << %Q[capture: unwrap #{qid};]
			  		#stata << %Q[capture: replace #{qid}=subinstr(#{qid},"---","",1);]
			  		#stata << %Q[capture: replace #{qid}=subinstr(#{qid}," '","",1);]
			  		#stata << %Q[capture: replace #{qid}=subinstr(#{qid},"' ","",1);]
			  		#stata << %Q[capture: replace #{qid}=subinstr(#{qid},"  ... ","",1);]
			  		csv << ["#{section_number}", "#{question_count}", "#{qid}", question.uniqueid, question.identifier, 
			  						question.type, question.question_text.original, "", ""]
			  		#q_list << row
			  	end
			  	# treatment of special

			  end
			  puts "--------------------#{question_count} \n"
			end
			#puts "#{question_count}"
			stata << %Q[#delimit cr]
			#stata << %Q[compress]
			#stata << %Q[destring *, replace]
			#stata << %Q[order __*]
			#stata << %Q[save "../stata/#{survey["hash"]}.dta", replace]
			#stata << %Q[drop *edit*]
			#stata << %Q[save "../stata/#{survey["hash"]}_s.dta", replace]
			#stata << %Q[drop *other *special]
			#stata << %Q[save "../stata/#{survey["hash"]}_ss.dta", replace]
			#stata << %Q[]
			path = "#{stata_paths}/lab_#{hash}.do"
			File.open(path, 'w') {|f| f.write(stata.join("\n")) }
			#CSV.open("#{stata_paths}/q_#{hash}.csv", 'w') {|csv| csv.write(q_list,join("\n")) }
		end
	end

	path_hash_list = "#{stata_paths}/hash_list.do"
	File.open(path_hash_list, 'w') {|f| f.write(hash_list.join("\n")) }
	
end