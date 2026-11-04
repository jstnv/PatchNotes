extends SceneTree
var checks:=0
var failures:Array[String]=[]
func expect(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures.append(message);push_error(message)
func _initialize()->void:
 await process_frame
 var first:Dictionary={}
 for i in 2100:
  var record:=ReleasedGameSales.create(StringName("bound-"+str(i)),100+i)
  expect(not record.is_empty(),"Valid distinct record "+str(i))
  if i==0:first=record.duplicate(true)
 expect(ReleasedGameSales._validated_records.size()<=ReleasedGameSales.VALIDATED_RECORD_LIMIT,"Entry cap maintained")
 expect(ReleasedGameSales._validated_lookup.size()==ReleasedGameSales._validated_records.size(),"Lookup and ordered entries agree")
 expect(ReleasedGameSales._validated_record_bytes<=ReleasedGameSales.VALIDATED_RECORD_BYTES,"Byte cap maintained")
 expect(ReleasedGameSales.is_valid(first),"Evicted valid record revalidates")
 var corrupted:=first.duplicate(true);corrupted.total_units=-1
 expect(not ReleasedGameSales.is_valid(corrupted),"Altered record cannot reuse exact proof")
 var same:=first.duplicate(true)
 expect(ReleasedGameSales.is_valid(same),"Independent equal typed value can reuse proof")
 var report={"checks":checks,"failures":failures,"entries":ReleasedGameSales._validated_records.size(),"bytes":ReleasedGameSales._validated_record_bytes}
 var out:=FileAccess.open(OS.get_environment("PN_PERF_REPORT"),FileAccess.WRITE);out.store_string(JSON.stringify(report));out.close()
 print("SALES_CACHE_BOUNDS ",JSON.stringify(report));quit(0 if failures.is_empty() else 1)
