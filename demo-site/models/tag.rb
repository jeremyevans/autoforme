module AutoFormeDemo
class Tag < Model
  many_to_many :albums
end
end
