
require 'chunky_png'
require 'delegate'

class Bitmap < SimpleDelegator

  def initialize(*args)
    case args.size
    when 1
      filename, = args
      filename += '.png' unless filename.end_with? '.png'
      @image = ChunkyPNG::Image.from_file filename
    when 2
      @image = ChunkyPNG::Image.new(*args)
    end
    super @image
  end

  # def compose(other)

  def save(filename, option = :best_compression)
    @image.save(filename, option)
    self
  end

  # def crop(x, y, w, h)

  # bilinear, nearest_neighbor
  def scale(w, h, method = :bilinear)
    @image.send("resample_#{method}!", w, h)
    self
  end
end
