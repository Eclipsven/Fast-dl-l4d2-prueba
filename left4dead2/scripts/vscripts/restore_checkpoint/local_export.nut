/*
	Restore Checkpoint System
	Local export / import module

	このファイルは restore_checkpoint.nut の ::rs_cp 作成後に IncludeScript すること。
*/

::rs_cp.getLocalMapDataPath <- function()
{
	return ::rs_cp.dir_mapdata + ::rs_cp.s_MapName + ".txt";
}

::rs_cp.escapeLocalExportString <- function(text)
{
	local result = "";

	for(local i = 0; i < text.len(); i++){
		local ch = text[i].tochar();

		if(ch == "\\")
			result += "\\\\";
		else if(ch == "\"")
			result += "\\\"";
		else if(ch == "\n")
			result += "\\n";
		else if(ch == "\r")
			result += "\\r";
		else if(ch == "\t")
			result += "\\t";
		else
			result += ch;
	}

	return result;
}

::rs_cp.localValueToText <- function(value)
{
	if(value == null)
		return "null";

	local value_type = typeof value;

	if(value_type == "integer" || value_type == "float")
		return value.tostring();

	if(value_type == "bool")
		return value ? "true" : "false";

	if(value_type == "string")
		return "\"" + ::rs_cp.escapeLocalExportString(value) + "\"";

	if(value_type == "array"){
		local text = "[";
		local first = true;

		foreach(v in value){
			if(!first)
				text += ", ";
			first = false;

			text += ::rs_cp.localValueToText(v);
		}

		text += "]";
		return text;
	}

	if(value_type == "table"){
		local text = "{";
		local first = true;

		foreach(k, v in value){
			if(!first)
				text += ", ";
			first = false;

			text += "[" + ::rs_cp.localValueToText(k.tostring()) + "] = " + ::rs_cp.localValueToText(v);
		}

		text += "}";
		return text;
	}

	// SaveTable に入れられない型と同じく、entity / function / instance 等は保存しない
	return "\"\"";
}

::rs_cp.getLocalCheckpointIndex <- function()
{
	local result = -1;

	if(::rs_cp.trulySaveFlow <= 0)
		return result;

	foreach(i, value in ::rs_cp.commonList){
		if(value == null || !("flow" in value))
			continue;

		if(value.flow <= ::rs_cp.trulySaveFlow)
			result = i;
	}

	return result;
}

::rs_cp.localNumericTableToArray <- function(value)
{
	if(value == null)
		return [];

	if(typeof value == "array")
		return value;

	if(typeof value != "table")
		return [];

	local result = [];

	foreach(k, v in value){
		local index = -1;

		try{
			index = k.tointeger();
		}
		catch(e){
			continue;
		}

		if(index < 0)
			continue;

		while(result.len() <= index)
			result.append(null);

		result[index] = v;
	}

	local compact = [];
	foreach(v in result){
		if(v != null)
			compact.append(v);
	}

	return compact;
}

::rs_cp.localShallowCopyArray <- function(src)
{
	local dst = [];

	if(src == null || typeof src != "array")
		return dst;

	foreach(v in src)
		dst.append(v);

	return dst;
}

::rs_cp.makeLocalExportTextUnderLimit <- function(data)
{
	local maxChars = 15000;
	if("localExportReadSafeChars" in ::rs_cp)
		maxChars = ::rs_cp.localExportReadSafeChars;

	local text = ::rs_cp.localValueToText(data);

	if(text.len() <= maxChars)
		return text;

	local removedCount = 0;

	// 古いストックから削る。
	// checkpointCommon / checkpointSurvivors は別に保持しているため、自動復元は維持される。
	while(text.len() > maxChars){
		local removed = false;

		if(("commonList" in data) && typeof data.commonList == "array" && data.commonList.len() > 0){
			data.commonList.remove(0);
			removed = true;
		}

		if(("survivorsList" in data) && typeof data.survivorsList == "array" && data.survivorsList.len() > 0){
			data.survivorsList.remove(0);
			removed = true;
		}

		if(!removed)
			break;

		removedCount++;
		text = ::rs_cp.localValueToText(data);
	}

	if(removedCount > 0){
		::rs_cp.debugPrint(format(
			"Local export trimmed old stock data. removed=%d len=%d limit=%d",
			removedCount,
			text.len(),
			maxChars
		));
	}

	if(text.len() <= maxChars)
		return text;

	// それでも長い場合は、履歴を完全に捨てて checkpoint だけ残す
	data.commonList = [];
	data.survivorsList = [];

	text = ::rs_cp.localValueToText(data);

	if(text.len() <= maxChars){
		::rs_cp.debugPrint(format(
			"Local export saved checkpoint-only data. len=%d limit=%d",
			text.len(),
			maxChars
		));
		return text;
	}

	// checkpoint本体だけでも長い場合、1ファイル方式では安全に読めない
	::rs_cp.debugPrint(format(
		"Local export failed: checkpoint data is still too large. len=%d limit=%d",
		text.len(),
		maxChars
	));

	return null;
}

::rs_cp.saveLocalMapData <- function(checkpointCommon = null, checkpointSurvivors = null)
{
	if(!::rs_cp.exportLocalFile)
		return false;

	if(::rs_cp.s_MapName == "")
		return false;

	local data = {};
	data["version"] <- version;
	data["map"] <- ::rs_cp.s_MapName;
	data["lastFlow"] <- ::rs_cp.lastFlow;
	data["trulySaveFlow"] <- ::rs_cp.trulySaveFlow;
	data["commonList"] <- ::rs_cp.localShallowCopyArray(::rs_cp.commonList);
	data["survivorsList"] <- ::rs_cp.localShallowCopyArray(::rs_cp.survivorsList);

	local gt_data = {};
	RestoreTable("rs_table", gt_data);
	data["restoreOFF"] <- (("restoreOFF" in gt_data) && gt_data["restoreOFF"]);
	SaveTable("rs_table", gt_data);

	if(checkpointCommon != null && checkpointSurvivors != null){
		data["checkpointCommon"] <- checkpointCommon;
		data["checkpointSurvivors"] <- checkpointSurvivors;
	}
	else{
		local checkpointIndex = ::rs_cp.getLocalCheckpointIndex();

		if(checkpointIndex >= 0 && checkpointIndex < ::rs_cp.commonList.len()){
			data["checkpointCommon"] <- ::rs_cp.commonList[checkpointIndex];

			local survIndex = checkpointIndex;
			if(survIndex >= ::rs_cp.survivorsList.len())
				survIndex = ::rs_cp.survivorsList.len() - 1;
			if(survIndex < 0)
				survIndex = 0;

			if(::rs_cp.survivorsList.len() > 0)
				data["checkpointSurvivors"] <- ::rs_cp.survivorsList[survIndex];
			else
				data["checkpointSurvivors"] <- [];
		}
		else{
			data["checkpointCommon"] <- {};
			data["checkpointSurvivors"] <- [];
		}
	}

	local text = ::rs_cp.makeLocalExportTextUnderLimit(data);
	if(text == null)
		return false;

	StringToFile(::rs_cp.getLocalMapDataPath(), text);

	::rs_cp.debugPrint(format(
		"Local map data saved: %s len=%d",
		::rs_cp.getLocalMapDataPath(),
		text.len()
	));

	return true;
}

::rs_cp.loadLocalMapData <- function()
{
	if(!::rs_cp.exportLocalFile)
		return false;

	if(::rs_cp.s_MapName == "")
		return false;

	local path = ::rs_cp.getLocalMapDataPath();
	local text = FileToString(path);

	if(text == null)
		return false;

	if(::rs_cp.trimSettingText(text).len() <= 0)
		return false;

	local data = null;

	try{
		local func = compilestring("return " + text);
		data = func();
	}
	catch(e){
		::rs_cp.debugPrint("Failed to load local map data: compile error.");
		return false;
	}

	if(data == null || typeof data != "table"){
		::rs_cp.debugPrint("Failed to load local map data: invalid root data.");
		return false;
	}

	if(!("map" in data) || data.map != ::rs_cp.s_MapName){
		::rs_cp.debugPrint("Local map data ignored: map mismatch.");
		return false;
	}

	if(!("version" in data) || data.version != version){
		::rs_cp.debugPrint("Local map data ignored: version mismatch.");
		return false;
	}

	if(!("commonList" in data) || typeof data.commonList != "array"){
		::rs_cp.debugPrint("Local map data ignored: commonList missing.");
		return false;
	}

	if(!("survivorsList" in data) || (typeof data.survivorsList != "array" && typeof data.survivorsList != "table")){
		::rs_cp.debugPrint("Local map data ignored: survivorsList missing.");
		return false;
	}

	data.survivorsList = ::rs_cp.localNumericTableToArray(data.survivorsList);

	for(local i = 0; i < data.survivorsList.len(); i++)
		data.survivorsList[i] = ::rs_cp.localNumericTableToArray(data.survivorsList[i]);

	if(!("checkpointCommon" in data) || typeof data.checkpointCommon != "table" || data.checkpointCommon.len() <= 0){
		::rs_cp.debugPrint("Local map data loaded, but checkpointCommon is empty.");
		return false;
	}

	if(!("checkpointSurvivors" in data) || (typeof data.checkpointSurvivors != "array" && typeof data.checkpointSurvivors != "table")){
		::rs_cp.debugPrint("Local map data ignored: checkpointSurvivors missing.");
		return false;
	}

	data.checkpointSurvivors = ::rs_cp.localNumericTableToArray(data.checkpointSurvivors);

	::rs_cp.localMapDataLoaded = true;
	::rs_cp.localCheckpointSurvivorCount = data.checkpointSurvivors.len();
	
	::rs_cp.debugPrint(format("Local checkpoint survivor count: %d", ::rs_cp.localCheckpointSurvivorCount));

	::rs_cp.commonList = data.commonList;
	::rs_cp.survivorsList = data.survivorsList;

	if("lastFlow" in data)
		::rs_cp.lastFlow = data.lastFlow;

	if("trulySaveFlow" in data)
		::rs_cp.trulySaveFlow = data.trulySaveFlow;

	if("flow" in data.checkpointCommon)
		::rs_cp.lastRestoreLibraryBucket = ::rs_cp.getRestoreLibraryBucket(data.checkpointCommon.flow);

	SaveTable("rs_common", data.checkpointCommon);
	SaveTable("rs_survivors", { list = data.checkpointSurvivors });

	local gt_data = {};
	RestoreTable("rs_table", gt_data);

	// ゲーム再起動直後でも tryRestoreCheckpoint() が復元処理へ入れるようにする
	gt_data["gametime"] <- -1.0;

	if("restoreOFF" in data)
		gt_data["restoreOFF"] <- data.restoreOFF;

	SaveTable("rs_table", gt_data);

	::rs_cp.isRestoreOFF = ("restoreOFF" in gt_data && gt_data["restoreOFF"]);

	// 手動復元用ライブラリも、ローカルに残っているストックから復元しておく
	::rs_cp.stockCurrentRoundToRestoreLibrary();

	::rs_cp.debugPrint("\x04" + "Local map data loaded: " + path);
	
	return true;
}

::rs_cp.clearLocalMapData <- function()
{
	if(!::rs_cp.exportLocalFile)
		return;
	
	if(::rs_cp.s_MapName == "")
		return;

	local path = ::rs_cp.getLocalMapDataPath();

	// VScript では削除関数が安定して使えないため、空ファイル化して無効化する
	StringToFile(path, "");

	::rs_cp.debugPrint("Local map data cleared: " + path);
}