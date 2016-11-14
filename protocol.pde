
import java.nio.ByteBuffer;

final byte STARTBYTE = 0x7E;
final byte STOPBYTE = 0x7F;
final byte ESCAPEBYTE = 0x7D;
final byte SPEEDCOMMAND_ID = 1;
final byte PIDCOMMAND_ID = 2;

byte[] get_speed_command(float x, float y, float theta, byte id){
  ByteBuffer result = ByteBuffer.allocate(14);
  result.put(id);
  result.put(SPEEDCOMMAND_ID);
  result.put(float_to_bytes(x));
  result.put(float_to_bytes(y));
  result.put(float_to_bytes(theta));
  
  return _pack_command(result);
}

byte[] float_to_bytes(float f){
  byte[] b = new byte[4];
  ByteBuffer buf = ByteBuffer.wrap(b);
  buf.putFloat(f);
  
  byte[] result = new byte[4];
  result[0] = b[3];
  result[1] = b[2];
  result[2] = b[1];
  result[3] = b[0];
  return result;
}

byte[] _pack_command(ByteBuffer command){
  
  ByteBuffer result = ByteBuffer.allocate(100);
  result.put(STARTBYTE);
  for(int i = 0; i < command.position(); i++){
    byte b = command.get(i);
    if (b == STARTBYTE || b == STOPBYTE || b == ESCAPEBYTE){
      result.put(ESCAPEBYTE);
    }
    result.put(b);
  }
  result.put(STOPBYTE);
  println(result.position());
  println(result.toString());
  byte[] bytes = new byte[result.position()];
  result.rewind();
  result.get(bytes);
  return bytes;
}