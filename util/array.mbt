///|
pub fn[T] repeat(x : T, count : Int) -> Array[T] {
  Array::from_fixed_array(FixedArray::make(count, x))
}
