is_rgss = Object.const_defined? :RPG
is_pure_ruby = !is_rgss

# 该模块被所有 RPGObject 中的类（纯 Ruby）或 RPG 模块下下的类（RGSS）混入
module RPGObject

  CLASS_KEY = :__class__

  PACK_RPG_OBJECT = lambda do |obj|
    case obj
    when Hash
      if obj.key?(CLASS_KEY)
        RPGObject.load_hash(obj)
      else
        obj.each_with_object({}) do |(key, value), hash|
          hash[PACK_RPG_OBJECT.call key] = PACK_RPG_OBJECT.call value
        end
      end
    when Array
      obj.map(&PACK_RPG_OBJECT)
    else
      obj
    end
  end

  UNPACK_RPG_OBJECT = lambda do |obj|
    case obj
    when RPGObject
      obj.to_h
    when Array
      obj.map(&UNPACK_RPG_OBJECT)
    when Hash
      obj.each_with_object({}) do |(key, value), hash|
        hash[UNPACK_RPG_OBJECT.call key] = UNPACK_RPG_OBJECT.call value
      end
    else
      obj
    end
  end

  define_singleton_method :pack_rpg_object,   PACK_RPG_OBJECT
  define_singleton_method :unpack_rpg_object, UNPACK_RPG_OBJECT

  module ClassMethod
    # 通过 hash 生成 self 类的实例
    def init_from_hash(hash)
      hash.each_with_object allocate do |(key, value), obj|
        obj.instance_variable_set(:"@#{key}", PACK_RPG_OBJECT.call(value))
      end
    end
  end

  extend ClassMethod

  # 使得混入的所有类都具有 init_from_hash 方法
  def self.included(klass)
    klass.extend ClassMethod
  end

  # 将 hash 还原为对象
  # 在纯 Ruby 下还原为 RPGObject，在 RGSS 下还原为原本的对象
  def self.load_hash(hash)
    hash = hash.dup
    Object.const_get(hash.delete(CLASS_KEY)).init_from_hash(hash)
  end

  # 将 rvdata2 文件转为 RPGObject 对象（纯 Ruby）或等价于 load_data（RGSS）
  def self.load_rvdata2(filename)

    File.open(filename) { |file| Marshal.load(file) }

  rescue ArgumentError => e

    current_class = Object

    #            'RPG::Actor'.split('::').each do |name|
    e.message.split(' ').last.split('::').each do |class_name|
      next if class_name.empty?
      current_class = current_class.const_get class_name, false
    end

    retry
  end

  # 转化为 hash，可以将 hash 进一步转化为可读的字符串
  def to_h
    ret = {CLASS_KEY => self.class.name}
    instance_variables.each do |key|
      value = instance_variable_get(key)

      # 去掉开头的 @
      ret[key[1..-1]] = UNPACK_RPG_OBJECT.call value
    end
    ret
  end
end

if is_pure_ruby

# 以下定义仅使得 Marshal.load 时保存所有数据并且不报错
# 并非与 RGSS 中的定义等价

module RPG

  module ConstMissing
    def const_missing(const_name)
      const_set const_name, ::Class.new {
        include RPGObject
        extend ConstMissing
      }
    end
  end

  extend ConstMissing
end

class RPGObject::RGB

  include RPGObject

  def self.attr_other(other)
    attr_accessor other
    alias_method :other, other
    alias_method :other=, :"#{other}="
  end

  def initialize(*rgbo)
    self.red, self.green, self.blue, self.other = rgbo
  end

  attr_accessor :red, :green, :blue, :other

  def _dump(_)
    [red, green, blue, other].pack('D4')
  end

  def self._load(data)
    new(*data.unpack('D4'))
  end
end

class Color < RPGObject::RGB
  attr_other :alpha
end

class Tone < RPGObject::RGB
  attr_other :gray
end

class Table

  def initialize(unpacked_data)
    @dimension, @xsize, @ysize, @zsize, _, *@stored_data = unpacked_data
  end

  def [](x, y = 0, z = 0)
    @stored_data[calc_offset(x, y, z)]
  end

  def []=(x, y = 0, z = 0, value)
    @stored_data[calc_offset(x, y, z)] = value
  end

  def _dump(_)
    [
      @dimension,
      @xsize,
      @ysize,
      @zsize,
      @xsize * @ysize * @zsize,
      *@stored_data
    ].pack('L5s*')
  end

  def self._load(data)
    new data.unpack('L5s*')
  end

  def calc_offset(x, y = 0, z = 0)
    z * @ysize * @xsize + y * @xsize + x
  end
end

else
  # if is_rgss

  # 将 RPG 内部的所有模块混入 RPGObject
  traverse_module = lambda do |mod|
    mod.constants(false).each do |const_name|
      const = mod.const_get const_name
      if const.kind_of? Module
        const.send :include, RPGObject
        traverse_module.call const
      end
    end
  end

  traverse_module.call RPG

  class Table
    def self.init_from_hash(hash)

      xsize = hash.fetch(:xsize)
      ysize = hash.fetch(:ysize)
      zsize = hash.fetch(:zsize)

      _load [
        hash.fetch(:dimension),
        xsize,
        ysize,
        zsize,
        xsize * ysize * zsize,
        *hash.fetch(:stored_data)
      ].pack('L5s*')
    end
  end

end  # if is_pure_ruby

# 公共部分
class Table

  include RPGObject

  def to_h
    dimension, xsize, ysize, zsize, _, *stored_data = _dump(-1).unpack('L5s*')
    {
      CLASS_KEY => "Table",
      "dimension" => dimension,
      "xsize" => xsize,
      "ysize" => ysize,
      "zsize" => zsize,
      "stored_data" => stored_data
    }
  end
end

class Color

  include RPGObject

  def self.init_from_hash(hash)
    new(
      hash.fetch("red"),
      hash.fetch("green"),
      hash.fetch("blue"),
      hash.fetch("alpha")
    )
  end

  def to_h
    {
      CLASS_KEY => "Color",
      "red" => red,
      "green" => green,
      "blue" => blue,
      "alpha" => alpha
    }
  end
end

class Tone

  include RPGObject

  def self.init_from_hash(hash)
    new(
      hash.fetch("red"),
      hash.fetch("green"),
      hash.fetch("blue"),
      hash.fetch("gray")
    )
  end

  def to_h
    {
      CLASS_KEY => "Tone",
      "red" => red,
      "green" => green,
      "blue" => blue,
      "gray" => gray
    }
  end
end
