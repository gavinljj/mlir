// RUN: mlir-tblgen -gen-op-defs -I %S/../../include %s | FileCheck %s

include "mlir/IR/OpBase.td"

def SomeAttr : Attr<CPred<"some-condition">, "some attribute kind"> {
  let storageType = "some-attr-kind";
  let returnType = "some-return-type";
  let convertFromStorage = "{0}.some-convert-from-storage()";
  let constBuilderCall = "some-const-builder-call({0}, {1})";
}

def AOp : Op<"a_op", []> {
  let arguments = (ins
      SomeAttr:$aAttr,
      DefaultValuedAttr<SomeAttr, "4.2">:$bAttr,
      OptionalAttr<SomeAttr>:$cAttr
  );
}

// CHECK-LABEL: AOp definitions

// Test getter methods
// ---

// CHECK:      some-return-type AOp::aAttr() {
// CHECK-NEXT:   auto attr = this->getAttr("aAttr").dyn_cast_or_null<some-attr-kind>();
// CHECK-NEXT:   return attr.some-convert-from-storage();

// CHECK:      some-return-type AOp::bAttr() {
// CHECK-NEXT:   auto attr = this->getAttr("bAttr").dyn_cast_or_null<some-attr-kind>();
// CHECK-NEXT:   if (!attr)
// CHECK-NEXT:       return some-const-builder-call(mlir::Builder(this->getContext()), 4.2).some-convert-from-storage();
// CHECK-NEXT:   return attr.some-convert-from-storage();

// CHECK:      Optional<some-return-type> AOp::cAttr() {
// CHECK-NEXT:   auto attr = this->getAttr("cAttr").dyn_cast_or_null<some-attr-kind>();
// CHECK-NEXT:   return attr ? Optional<some-return-type>(attr.some-convert-from-storage()) : (llvm::None);

// Test build methods
// ---

// CHECK:      void AOp::build(
// CHECK:        tblgen_state->addAttribute("aAttr", aAttr);
// CHECK:        tblgen_state->addAttribute("bAttr", bAttr);
// CHECK:        if (cAttr) {
// CHECK-NEXT:     tblgen_state->addAttribute("cAttr", cAttr);

// CHECK:      void AOp::build(
// CHECK-SAME:   ArrayRef<NamedAttribute> attributes
// CHECK:        for (const auto& pair : attributes)
// CHECK-NEXT:     tblgen_state->addAttribute(pair.first, pair.second);

// Test verify method
// ---

// CHECK:      AOp::verify()
// CHECK:      auto tblgen_aAttr = this->getAttr("aAttr");
// CHECK-NEXT: if (!tblgen_aAttr) return emitOpError("requires attribute 'aAttr'");
// CHECK:        if (!((some-condition))) return emitOpError("attribute 'aAttr' failed to satisfy constraint: some attribute kind");
// CHECK:      auto tblgen_bAttr = this->getAttr("bAttr");
// CHECK-NEXT: if (tblgen_bAttr) {
// CHECK-NEXT:   if (!((some-condition))) return emitOpError("attribute 'bAttr' failed to satisfy constraint: some attribute kind");
// CHECK:      auto tblgen_cAttr = this->getAttr("cAttr");
// CHECK-NEXT: if (tblgen_cAttr) {
// CHECK-NEXT:   if (!((some-condition))) return emitOpError("attribute 'cAttr' failed to satisfy constraint: some attribute kind");
 
def SomeTypeAttr : TypeAttrBase<"SomeType", "some type attribute">;

// Test common attribute kinds' constraints
// ---

def BOp : Op<"b_op", []> {
  let arguments = (ins
    AnyAttr:$any_attr,
    BoolAttr:$bool_attr,
    I32Attr:$i32_attr,
    I64Attr:$i64_attr,
    F32Attr:$f32_attr,
    F64Attr:$f64_attr,
    StrAttr:$str_attr,
    ElementsAttr:$elements_attr,
    FunctionAttr:$function_attr,
    SomeTypeAttr:$type_attr,
    ArrayAttr:$array_attr,
    TypedArrayAttrBase<SomeAttr, "SomeAttr array">:$some_attr_array
  );
}

// CHECK-LABEL: BOp::verify
// CHECK: if (!((true)))
// CHECK: if (!((tblgen_bool_attr.isa<BoolAttr>())))
// CHECK: if (!(((tblgen_i32_attr.isa<IntegerAttr>())) && ((tblgen_i32_attr.cast<IntegerAttr>().getType().isInteger(32)))))
// CHECK: if (!(((tblgen_i64_attr.isa<IntegerAttr>())) && ((tblgen_i64_attr.cast<IntegerAttr>().getType().isInteger(64)))))
// CHECK: if (!(((tblgen_f32_attr.isa<FloatAttr>())) && ((tblgen_f32_attr.cast<FloatAttr>().getType().isF32()))))
// CHECK: if (!(((tblgen_f64_attr.isa<FloatAttr>())) && ((tblgen_f64_attr.cast<FloatAttr>().getType().isF64()))))
// CHECK: if (!((tblgen_str_attr.isa<StringAttr>())))
// CHECK: if (!((tblgen_elements_attr.isa<ElementsAttr>())))
// CHECK: if (!((tblgen_function_attr.isa<FunctionAttr>())))
// CHECK: if (!(((tblgen_type_attr.isa<TypeAttr>())) && ((tblgen_type_attr.cast<TypeAttr>().getValue().isa<SomeType>()))))
// CHECK: if (!((tblgen_array_attr.isa<ArrayAttr>())))
// CHECK: if (!(((tblgen_some_attr_array.isa<ArrayAttr>())) && (llvm::all_of(tblgen_some_attr_array.cast<ArrayAttr>(), [](Attribute attr) { return (some-condition); }))))


def MixOperandsAndAttrs : Op<"mix_operands_and_attrs", []> {
  let arguments = (ins F32Attr:$attr, F32:$operand, F32Attr:$otherAttr, F32:$otherArg);
}

// CHECK-LABEL: MixOperandsAndAttrs definitions
// CHECK-DAG: Value *MixOperandsAndAttrs::operand()
// CHECK-DAG: Value *MixOperandsAndAttrs::otherArg()
// CHECK-DAG: void MixOperandsAndAttrs::build(Builder *, OperationState *tblgen_state, FloatAttr attr, Value *operand, FloatAttr otherAttr, Value *otherArg)
// CHECK-DAG: APFloat MixOperandsAndAttrs::attr()
// CHECK-DAG: APFloat MixOperandsAndAttrs::otherAttr()
