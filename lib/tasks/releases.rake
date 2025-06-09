namespace :releases do
  desc "Generate slugs for releases that don't have one"
  task :generate_slugs => :environment do
    Release.where(slug: [nil, '']).each do |release|
      base_slug = release.title.parameterize
      slug = base_slug
      counter = 1

      while release.user.releases.where.not(id: release.id).exists?(slug: slug)
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end

      release.update_column(:slug, slug)
      puts "Generated slug '#{slug}' for release '#{release.title}'"
    end
  end
end
