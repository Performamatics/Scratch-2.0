// Variable.as
// John Maloney, February 2010
//
// A variable is a name-value pair.

package interpreter {
	import util.JSON_AB;

public class Variable {

	public var name:String;
	public var value:*;
	public var watcher:*;
	public var isPersistent:Boolean;

	public function Variable(vName:String, initialValue:*) {
		name = vName;
		value = initialValue;
	}

	public function writeJSON( json:JSON_AB ):void {
		json.writeKeyValue('name', name);
		json.writeKeyValue('value', value);
		json.writeKeyValue('isPersistent', isPersistent);
	}

}}
