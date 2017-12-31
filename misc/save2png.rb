
# thanks to @dant and @SixRC
class Bitmap
  def save_to_png(filename)
    kg=[width].pack('N')+[height].pack('N')
    c1='IHDR'<<kg<<"\x8\x6\x0\x0\x0"
    crc1=[Zlib.crc32(c1)].pack('N')
    data="\0"*(width*height*4+height)
    Win32API.new('user32.dll','CallWindowProc','ppiii','i').call("U\x8B\xEC\x8BE\x10\x8B]\f\x8Bu\b3\xFFk\xC0\x04\x89E\b\x8BM\x103\xC0\x89\x047\x83\xC7\x01\x8BU\x14\x0F\xAFU\b\x8B\xC1k\xC0\x04+\xD0\x8B\x04\x1A\x0F\xC8\xC1\xC8\b\x89\x047\x83\xC7\x04\xE2\xE2\x8BE\x14H\x89E\x14\x83\xF8\x00u\xCB\x8B\xE5]\xC2\x10\x00",data,"\0\0\0\0".tap { |s| Win32API.new('user32.dll','CallWindowProc','ppiii','i').call("\x8Bt$\b\x8B6\x8Bv\b\x8Bv\x10\x8B|$\x04\x897\xC2\x10\x00",s,__id__*2+16,0,0)}.unpack('L').first,width,height)
    data = Zlib::Deflate.deflate(data)
    crc2=[Zlib.crc32('IDAT'<<data)].pack('N')
    sod=[data.length].pack('N')
    File.open(filename,'wb'){|i|i<<"\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x0\x0\x0\xdIHDR"<<kg<<"\x8\x6\x0\x0\x0"<<crc1<<sod<<'IDAT'<<data<<crc2<<"\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82"}
  end
end
