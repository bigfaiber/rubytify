class SpotifyImporter

  def import_artists
    artist_names = SpotifyImporter.load_yaml
    p "Artists YAML loaded" if artist_names
    p "-"*20
    p "Fetching data"
    artist_names.each do |name|
      spotify_artist = SpotifyImporter.get_artist name
      if spotify_artist
        local_artist = SpotifyImporter.create_artist spotify_artist
        SpotifyImporter.create_albums(local_artist, spotify_artist)
        SpotifyImporter.set_genres(local_artist, spotify_artist)
      end
      p "Artist #{name} succesfuly imported"
    end
  end

  class << self
    def create_albums local_artist, spotify_artist
      return unless local_artist&.persisted?
      spotify_artist.albums.each do |album|
        local_album = local_artist.albums.create(
            name: album.name,
            image: album.images&.first['url'],
            total_tracks: album.total_tracks,
            spotify_id: album.id,
            spotify_url: album.external_urls['spotify']
            )
        album.tracks.each do |track|
          local_album.songs.create(
              name: track.name,
              preview_url: track.preview_url,
              duration_ms: track.duration_ms,
              spotify_id: track.id,
              spotify_url: track.external_urls['spotify'],
              explicit: track.explicit
          )
        end
      end

    end
    def create_artist artist
      Artist.create(
          name: artist.name,
          image: artist.images&.first['url'],
          popularity: artist.popularity,
          spotify_url: artist.external_urls['spotify'],
          spotify_id: artist.id
      )
    end

    def get_artist name
      RSpotify::Artist.search(name).first
    rescue
      return {mssg: "Artist with name #{name} not found"}
    end

    def load_yaml
      YAML.load_file(Rails.root.join('db', 'artists.yml'))['artists']
    end

    def set_genres local_artist, spotify_artist
      spotify_artist.genres.each do |genre_name|
        local_genre = Genre.find_by(name: genre_name.downcase) ||
                      Genre.create(name: genre_name.downcase)
        local_artist.genres << local_genre
      end
    end
  end
end