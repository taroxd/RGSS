
long = 1 << 32

File.open('Game.rgss3a', 'rb') do |f|

  get4bytes = -> { f.read(4).unpack('L')[0] }
  raise unless f.read(8) == "RGSSAD\0\3"
  key = get4bytes.call * 9 + 3
  fdata = []
  loop do
    offset = get4bytes.call ^ key
    break if offset == 0
    length = get4bytes.call ^ key
    magickey = get4bytes.call ^ key
    fn_len = get4bytes.call ^ key
    fn = f.read(fn_len) + "\0\0\0\0"
    template = 'L' * ((fn_len + 3) / 4)
    fn = fn.unpack(template).map {|l| l ^ key }.pack(template)[0, fn_len]
    fdata.push [offset, length, magickey, fn]
  end

  fdata.each do |(offset, length, magickey, fn)|
    f.pos = offset
    data = f.read(length) + "\0\0\0\0"
    template = 'L' * ((length + 3) / 4)
    data = data.unpack(template).map do |l|
      l ^= magickey
      magickey = (magickey * 7 + 3) % long
      l
    end.pack(template)[0, length]
    fn.force_encoding Encoding::UTF_8
    paths = File.dirname(fn).split('\\')
    1.upto(paths.size) do |i|
      dir = paths.first(i).join('\\')
      Dir.mkdir(dir) unless Dir.exist?(dir)
    end
    File.open(fn, 'wb') {|wf| wf.write data }
  end
end
