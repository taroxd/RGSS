# @taroxd metadata 1.0
# @require taroxd_core
# @id check_object_dispose
# @display 检测未释放的对象

class Viewport
  def_before(:dispose) { @__dispose__ = true }
  def disposed?; @__dispose__; end
end

need_dispose = [Bitmap, Sprite, Window, Plane, Tilemap, Viewport]
callers = {}
callers.compare_by_identity
not_disposed = []

need_dispose.each do |klass|
  klass.class_eval do
    def_after(:initialize) { |*| callers[self] = caller }
  end
end

Scene_Base.class_eval do
  def_after :terminate do
    need_dispose.each do |klass|
      ObjectSpace.each_object(klass) do |obj|
        not_disposed.push(obj) unless obj.disposed?
      end
    end
  end

  def_after :update do
    return unless Input.trigger?(:ALT)
    puts not_disposed.delete_if(&:disposed?)
    puts callers[
      not_disposed.shuffle.find do |obj|
        callers[obj] && callers[obj].none? { |s| s.start_with?('{0004}') }
      end
    ]
  end
end