module IconHelper
  def icon_tag(name, variant: :solid, **options)
    options[:class] = Array(options[:class])
    options[:class] << "w-5 h-5" unless options[:class].any? { |c| c =~ /w-|h-/ }
    
    render partial: "shared/icons/#{variant}/#{name}", locals: { options: options }
  end
end
