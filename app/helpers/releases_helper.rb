module ReleasesHelper
  def release_type_bg_color(release_type)
    case release_type
    when "single" then "bg-blue-100 text-blue-800"
    when "ep" then "bg-purple-100 text-purple-800"
    when "album" then "bg-green-100 text-green-800"
    when "compilation" then "bg-yellow-100 text-yellow-800"
    else "bg-gray-100 text-gray-800"
    end
  end
end
