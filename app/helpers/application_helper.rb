module ApplicationHelper
    def is_active_controller(controller_name)
        params[:controller] == controller_name ? "active" : nil
    end

    def is_active_action(action_name)
        params[:action] == action_name ? "active" : nil
    end

    def nav_link(text, link)
	    recognized = Rails.application.routes.recognize_path(link)
	    if recognized[:controller] == params[:controller] && recognized[:action] == params[:action]
	        content_tag(:li, :class => "active") do
	            link_to( text, link)
	        end
	    else
	        content_tag(:li) do
	            link_to( text, link)
	        end
	    end
    	end

    	def link_to_add_fields(name, f, type)
      		new_object = f.object.send "build_#{type}"
      		id = "new_#{type}"
      		fields = f.send("#{type}_fields", new_object, child_index: id) do |builder|
        	render(type.to_s + "_fields", f: builder)
      		end
      		link_to(name, '#', class: "add_fields", data: {id: id, fields: fields.gsub("\n", "")})
    	end
end
