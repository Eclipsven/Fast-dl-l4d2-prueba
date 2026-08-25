local mp_gamemode = Convars.GetStr("mp_gamemode").tolower();
if(mp_gamemode == "survival" || mp_gamemode == "versus" || mp_gamemode == "scavenge" || mp_gamemode == "mutation15"){
	error("'Restore Checkpoint' failed to load. This add-on does not work in "+ mp_gamemode +" game mode.");
	return;
}

const version = "2026-07-01";

printl(format("<ADDON> Restore Checkpoint System loaded. v%s", version));

IncludeScript("restore_checkpoint/raya_timer");
IncludeScript("restore_checkpoint/lang_print");
IncludeScript("restore_checkpoint/introskip");


::rs_cp<-{
	/*
	*	SaveTableに null を使ってはいけない。
	*	
	*	↓入ってはいけないもの
	*	entityそのまま
	*	Vectorそのまま
	*	GetScriptScope()
	*	function
	*	instance
	*	null
	*/
	// 一度RestoreTableしたら保存データは消える。 連続でRestoreTableできないため、SaveTableで閉じる必要がある。
	
	/*
		【ロジック説明】
		
		thinkIntervalの間隔でセーブ処理が行われる。
		設定問わずパニックイベント中・フィナーレ開始後・ラウンド終了後はセーブ処理は行われない。
		
		
		人間プレイヤーの中から 最もFlowが高い生存者が選ばれる。
		人間プレイヤーがいなければBotの中から選ばれる。
		以下の生存者は対象外。
		・スタック中の生存者
		・不正なナビゲーションにいる生存者
		・はしごに登っている生存者
		・高さの足りない場所にいる生存者
		・ダウン中の生存者(任意)
		・特殊感染者に拘束されている生存者(任意)
		
		
		選ばれた生存者のFlowが前回セーブしたFlowより stockFlow以上高ければ、「その生存者の位置とFlow、各生存者のHP・インベントリ」のデータをセーブしてストックを溜める。
		死亡やダウンしていた生存者のHP・インベントリはセーブされない。 restoreHPがtrueの場合、死亡やダウンしていた生存者のHPは、Revive後と同じHP(仮体力30) となる。
		
		全滅時にloadIntervalFlow間隔で更新された最新のロードポイントが復元される。
		全滅時にパニックイベント中なら、最新のロードポイントのFlowから hordeBehindFlow%以上手前のストックから復元される(アドオンマップのみ)。
		
		パニックイベント・クレッシェンドイベントを確実に判定する方法が不明なため、CIの挙動で判定していて、CIがいないマップだと判定ができない。
	*/
	
	thinkInterval = 5.0				// [0.1 ~ 60.0]			データのセーブ処理を行うタイマーの間隔。 小さくするとセーブミスを減らせるが、環境によっては処理が重くなる。
	loadIntervalFlow = 20				// [1 ~ 99]				データをロードする進行度の間隔。 指定値が20の場合、Flowが20%以上進むたびにロードポイントが更新され、常に最新のものが復元に使われる。
	stockFlow = 5					// [1 ~ 20]				データのストックをするFlowの間隔。 指定値が小さいとこまめにセーブされるが、データ数が大きくなる。
	hordeBehindFlow = 5				// [-1 | 1 ~ 50]		アドオンマップのみ。ホード中に全滅した場合、現在のFlowから指定値以上後ろのFlowから復元する。 すぐにはホード判定を返せないため、パニックイベント中にセーブされてしまった場合、復元先がゲートが開いたあと等で詰む可能性がある。 -1で無効。
	disablePanicDelay = 15.0			// [0.1 ~ 60.0]			ゾンビのラッシュが落ち着いたと判断されてから、パニックイベント判定を切るまでの秒数。 実際にパニックイベント中でもゾンビの落ち着きがあるため、すぐに判定を切ると、パニックイベント中にセーブされてしまう。
	exclude_IncapSurv = false			// [true | false]		trueの場合、ダウン中の生存者をセーブ候補から除外する。
	exclude_DominatedSurv = false		// [true | false]		trueの場合、特殊感染者に拘束されている生存者をセーブ候補から除外する。
	noSave_DuringTankInPlay = true	// [true | false]		trueの場合、Tankと戦闘中の間はセーブしない。
	noSave_AfterFlow = -1				// [-1 | 50 ~ 100]		指定値のFlow以降ではセーブしない(セーブ処理タイマーを切る)。
	restoreTiming = 1				// [1 | 2]				復元を行うタイミング。 1=ラウンド開始時すぐ、2=セーフルームを出たら(アドオンマップだとセーフルームにいてもセーフルームを出た判定になることがある)。
	announce_Save = 2				// [0 ~ 2]				チェックポイントセーブに全体通知するかどうか。 0=無効、1=プリントのみ、2=プリントとサウンド。
	announce_Save_SndName = "EDIT_PLACE_PICK"	// ["string"]	announce_Saveが2の場合、全体通知時のサウンドスクリプト。
	announce_Restore = true			// [true | false]		trueの場合、復元の前に全体通知する。
	prohibitBehindTime = 60			// [-1 | 1 ~ 1800]		復元が成功したあと、指定値の秒数が経つまで、Tankと戦闘中に後ろにゾンビがスポーンすることを禁止する。 後方に湧いたCIで退路が塞がるのを防ぐため。 -1で無効。
	restore_FadeOut = true			// [true | false]		trueの場合、復元時に黒画面でフェードする。 マップ側でフェードアウト処理がある場合は効かない。
	restore_SndName = "Event.LargeAreaRevealed" // ["string"]	復元時のサウンドスクリプト。 空白の場合、音を鳴らさない。
	giveWepapon_AtLeast = 2			// [0 ~ 2]				復元が成功したあと、最低でも渡す武器。 0=何も渡さない(非推奨)、1=ハンドガンのみ、2=ハンドガンとTier1武器。
	giveAmmo = 0						// [0 ~ 2]				復元が成功したあと、プライマリ武器の弾薬数をgiveAmmo_Multiplyの倍率にセットするかどうか。 0=セットしない、1=常にセットする、2=弾薬が下回っているときだけセットする。
	giveAmmo_Multiply = 0.8			// [0.0 ~ 1.0]			giveAmmoが1以上の場合、セットする弾薬数の倍率。
	giveThrowable = 0				// [0 ~ 4]				復元が成功したあと、投擲スロットがカラの場合に、渡すアイテム。 0=渡さない、1=ランダム、2=Molotov、3=Pipe bomb、4=Vomitjar。
	giveMedkit = false				// [true | false]		trueの場合、復元が成功したあと、救急キットを渡す。
	giveTempHealItem = 0				// [0 ~ 3]				復元が成功したあと、一時回復アイテムスロットがカラの場合に、渡すアイテム。 0=渡さない、1=ランダム、2=Pain pills、3=Adrenaline。
	restoreHP = true					// [true | false]		trueの場合、HPを復元する。 falseの場合、ラウンド開始直後のHPのまま。
	restoreHP_AtLeast = 50			// [-1 | 2 ~ 100]		復元時にHPが指定値未満の場合、HPを指定値にセットする。 -1で無効。
	restoreHP_Type = 0				// [0 ~ 3]				指定値にセットするHPのパターン。 restoreHP_AtLeastが2以上で有効。 0=実体力で埋め合わせる、 1=仮体力で埋め合わせる、 2=実体力が不足していれば、実体力を足し、仮体力はそのまま残す、 3=実体力が不足していれば、実体力を足し、余った分だけ仮体力を残す。
	initiallyDisabled = false			// [true | false]		trueの場合、復元機能を最初から無効にする(ただしセーブ処理タイマーは継続動作する)。 !rscp on で有効化でき、!rscpコマンドが優先される。
	exportLocalFile = false			// [true | false]		trueの場合、ローカルファイルとしても書き出し、マップを完全にリスタートする場合やゲームを再起動した場合でも復元を可能にします。
	debug = false					// [true | false]		trueの場合、処理内容をサーバーのホストにのみ通知する。
	
	setting_keys = [
		"thinkInterval",
		"loadIntervalFlow",
		"stockFlow",
		"hordeBehindFlow",
		"disablePanicDelay",
		"exclude_IncapSurv",
		"exclude_DominatedSurv",
		"noSave_DuringTankInPlay",
		"noSave_AfterFlow",
		"restoreTiming",
		"announce_Save",
		"announce_Save_SndName",
		"announce_Restore",
		"prohibitBehindTime",
		"restore_FadeOut",
		"restore_SndName",
		"giveWepapon_AtLeast",
		"giveAmmo",
		"giveAmmo_Multiply",
		"giveThrowable",
		"giveMedkit",
		"giveTempHealItem",
		"restoreHP",
		"restoreHP_AtLeast",
		"restoreHP_Type",
		"initiallyDisabled",
		"exportLocalFile",
		"debug"
	]
	
	s_MapName = ""
	isInitiate = false
	initialPos = Vector(0,0,0)
	prohibitBehindStamp = 0
	isRestoreOFF = false
	isRoundEnd = false
	isFinaleStart = false
	isPanicEvent = 0.0
	isForceStopSave = false
	lastFlow = 0
	trulySaveFlow = 0
	dir_setting = "restore_checkpoint_system/rscp_settings.txt"
	dir_admin = "restore_checkpoint_system/admin_steam_id.txt"
	dir_mapdata = "restore_checkpoint_system/mapdata/"
	localExportReadSafeChars = 15000	//ScriptFileRead上限回避用
	
	adminSteamID = ""
	adminEntIndex = -1
	
	commonList = []
	survivorsList = []
	settingsLoadWarnings = []
	isVersionDifferent = false
	
	lastRestoreLibraryBucket = -1
	
	restoreDataCommon = {}
	restoreDataSurv = {}
	restoreUntilTime = 0.0
	restoreStamp = ""
	restoreUsedRowIndexes = {}
	
	isAlarmSoundActive = false
	
	localMapDataLoaded = false
	localCheckpointSurvivorCount = 0
	pendingLocalRestore = false
	introSkipDone = false

	isStartupLocalFileRestore = false 	//SaveTable が消えていて、local file から復元する場合だけ true

	// function OnGameEvent_round_start(params){} // ← player_spawnより遅い
	function OnGameEvent_player_spawn(params)
	{		
		local player = GetPlayerFromUserID(params.userid);
		if(player == null || !player.IsValid() || player.GetZombieType() != 9)
			return;
		
		/*::rs_cp.debugPrint(format(
			"player_spawn: name=%s bot=%s ztype=%d time=%.2f restoreUntil=%.2f",
			player.GetPlayerName(),
			IsPlayerABot(player) ? "true" : "false",
			player.GetZombieType(),
			Time(),
			::rs_cp.restoreUntilTime
		));*/

		if(!::rs_cp.isInitiate){
			::rs_cp.isInitiate = true;
			::rs_cp.initialPos = player.GetOrigin();
			
			// まだメモリに残っているときがあるので、マップを一番最初に始めたときに初期化
			if(Director.GetMissionWipes() == 0){
				SaveTable("rs_table", {});
				SaveTable("rs_common", {});
				SaveTable("rs_survivors", {});
				SaveTable("rs_history", {});
			}
			
			::rs_cp.save_ems_settings();
			::rs_cp.load_ems_settings();
			::rs_cp.printLoadedSettingsToConsole();
			
			if(IsDedicatedServer())
				::rs_cp.loadAdminSteamID();
			
			// initiallyDisabled = true なら復元処理しない
			// すでに rs_table.restoreOFF がある場合はそちらを優先する
			local gt_data = {};
			RestoreTable("rs_table", gt_data);
			if(!("restoreOFF" in gt_data))
				gt_data["restoreOFF"] <- ::rs_cp.initiallyDisabled;
			SaveTable("rs_table", gt_data);
			::rs_cp.isRestoreOFF = ("restoreOFF" in gt_data && gt_data["restoreOFF"]);
			// --------------------
			
			::rs_cp.s_MapName = Director.GetMapName().tolower();
			::rs_cp.setupAlarmSoundWatcher();
			
			local loadedLocal = false;
			local hasMemoryCheckpoint = ::rs_cp.hasMemoryCheckpointData();

			::rs_cp.isStartupLocalFileRestore = false;
			::rs_cp.localMapDataLoaded = false;
			::rs_cp.localCheckpointSurvivorCount = 0;

			if(::rs_cp.exportLocalFile && !hasMemoryCheckpoint){
				// SaveTable上に復元データがない（マップ完全再起動 / ゲーム再起動からの復元）場合だけ local file を取得。
				loadedLocal = ::rs_cp.loadLocalMapData();
				::rs_cp.isStartupLocalFileRestore = loadedLocal;
			}
			else if(hasMemoryCheckpoint){
				// 通常の全滅復元では、local file は読まず、従来通り SaveTable のデータで即復元する。
				::rs_cp.debugPrint("Memory checkpoint exists. Local file loading skipped.");
			}

			if(::rs_cp.restoreTiming == 1){
				if(::rs_cp.shouldUseDelayedStartupLocalRestore()){
					::rs_cp.startDelayedLocalRestore();
				}
				else{
					::rs_cp.tryRestoreCheckpoint();
					::rs_cp.isStartupLocalFileRestore = false;
				}
			}
			
			if(loadedLocal && !::rs_cp.isRestoreOFF)
				::rs_cp_print.printLang("local_file_restore_start");

			return;
		}

		if(::rs_cp.restoreUntilTime > Time())
			::rs_cp.restoreSingleSurvivor(player);
	}
	
	function getRestoreLibraryBucket(flow)
	{
		// stockFlow 単位に丸める。 例: stockFlow=5 のとき 37.4 -> 35, 21.2 -> 20
		if(flow < 0) return -1;
		return floor(flow.tofloat() / ::rs_cp.stockFlow) * ::rs_cp.stockFlow;
	}
	function stockCurrentRoundToRestoreLibrary()
	{
		local history_raw = {};
		RestoreTable("rs_history", history_raw);

		local history = {};
		history.list <- [];

		// RestoreTable() 後の list は配列でないことがあるため、
		// いったん新しい配列へ詰め直してから使う
		if("list" in history_raw){
			foreach(entry in history_raw.list){
				history.list.append(entry);
			}
		}

		// 今ラウンドでストックした地点を、手動復元用ライブラリへ追加していく
		for(local i = 0; i < ::rs_cp.commonList.len(); i++){
			local value = ::rs_cp.commonList[i];
			if(value == null || !("flow" in value))
				continue;

			local bucket = ::rs_cp.getRestoreLibraryBucket(value.flow);
			local exists = false;
			
			// 同じ flow バケットは 1件だけ保持する。
			// 既に存在する場合は自動上書きしない
			foreach(entry in history.list){
				if(("bucketFlow" in entry) && entry.bucketFlow == bucket){
					exists = true;
					break;
				}
			}
			if(exists)
				continue;

			local get_list = [];
			if(::rs_cp.survivorsList.len() > 0){
				local surv_index = i;
				
				// commonList と survivorsList の要素数がズレても落ちないように補正
				if(surv_index >= ::rs_cp.survivorsList.len())
					surv_index = ::rs_cp.survivorsList.len() - 1;
				if(surv_index < 0)
					surv_index = 0;

				get_list = ::rs_cp.survivorsList[surv_index];
				if(get_list == null)
					get_list = [];
			}

			// list表示や previous の扱いを安定させるため、
			// bucketFlow 昇順になる位置へ挿入する
			local insert_index = history.list.len();
			foreach(j, entry in history.list){
				if(("bucketFlow" in entry) && bucket < entry.bucketFlow){
					insert_index = j;
					break;
				}
			}

			history.list.insert(insert_index, {
				bucketFlow = bucket,
				common = value,
				survivors = get_list
			});
		}

		SaveTable("rs_history", history);
	}
	function getRestoreLibraryList()
	{
		local history = {};
		RestoreTable("rs_history", history);
		if(!("list" in history))
			history.list <- [];
		
		// RestoreTable() すると保存データが消えるため、
		// 読み出したあと必ず SaveTable() で戻しておく
		local result = history.list;
		SaveTable("rs_history", history);
		return result;
	}
	function findRestoreLibraryBucketByFlow(flow)
	{
		local history = {};
		RestoreTable("rs_history", history);
		if(!("list" in history))
			history.list <- [];

		// 指定 flow 以下の中で、最も近い bucketFlow を探す
		// 例: 43 を指定したら 40 を返す
		local result = -1;
		foreach(entry in history.list){
			if(!("bucketFlow" in entry))
				continue;

			if(entry.bucketFlow <= flow && (result < 0 || entry.bucketFlow > result))
				result = entry.bucketFlow;
		}

		SaveTable("rs_history", history);
		return result;
	}
	function findPreviousRestoreLibraryBucket(base_bucket)
	{
		local history = {};
		RestoreTable("rs_history", history);
		if(!("list" in history))
			history.list <- [];

		// 現在の復元地点より前にある bucket の中で、
		// 最も近い 1つ前の bucketFlow を返す
		local result = -1;
		foreach(entry in history.list){
			if(!("bucketFlow" in entry))
				continue;

			if(entry.bucketFlow < base_bucket && (result < 0 || entry.bucketFlow > result))
				result = entry.bucketFlow;
		}

		SaveTable("rs_history", history);
		return result;
	}
	function restoreFromLibraryBucket(bucket)
	{
		local history = {};
		RestoreTable("rs_history", history);
		if(!("list" in history))
			history.list <- [];

		// 指定された bucketFlow に一致する復元データを探す
		local entry = null;
		foreach(value in history.list){
			if(("bucketFlow" in value) && value.bucketFlow == bucket){
				entry = value;
				break;
			}
		}

		SaveTable("rs_history", history);

		if(entry == null || !("common" in entry) || !("survivors" in entry))
			return false;

		// 手動復元でも既存の復元処理をそのまま使えるように、
		// 一度 rs_common / rs_survivors に詰め直してから restoreStockData() を呼ぶ
		SaveTable("rs_common", entry.common);
		SaveTable("rs_survivors", { list = entry.survivors });

		// previous コマンド用に、最後に復元した bucket を記録
		::rs_cp.lastRestoreLibraryBucket = bucket;
		return ::rs_cp.restoreStockData(entry.common, { list = entry.survivors });
	}
	
	function countCurrentSurvivorsForDelayedRestore()
	{
		local count = 0;
		local tempCount = 0;

		for(local surv; surv = Entities.FindByClassname(surv, "player"); ){
			if(surv == null || !surv.IsValid() || surv.GetZombieType() != 9)
				continue;

			if(::rs_cp.isTemporaryL4LSurvivorClient(surv)){
				tempCount++;
				continue;
			}

			count++;
		}

		return [count, tempCount];
	}
	function hasMemoryCheckpointData()
	{
		local gt_data = {};
		RestoreTable("rs_table", gt_data);
		SaveTable("rs_table", gt_data);

		if(!("gametime" in gt_data))
			return false;

		local data_common = {};
		RestoreTable("rs_common", data_common);
		SaveTable("rs_common", data_common);

		if(data_common == null || data_common.len() <= 0)
			return false;

		local data_surv = {};
		RestoreTable("rs_survivors", data_surv);
		SaveTable("rs_survivors", data_surv);

		if(data_surv == null || !("list" in data_surv))
			return false;

		try{
			return data_surv.list.len() > 0;
		}
		catch(e){}

		return false;
	}

	function shouldUseDelayedStartupLocalRestore()
	{
		return (
			::rs_cp.exportLocalFile
			&& ::rs_cp.isStartupLocalFileRestore
			&& ::rs_cp.localCheckpointSurvivorCount > 4
		);
	}
	function tryIntroSkipOnce()
	{
		if(::rs_cp.introSkipDone)
			return;

		if(!Director.IsSessionStartMap())
			return;

		::rs_cp.introSkipDone = true;

		::rs_cp.debugPrint("Intro skip executed.");

		::rs_introFunc.introSkip();

		// introSkip() のマップ個別処理だけで足りない場合に備えて、
		// director解除とカメラDisableを複数回投げる
		if("forceFinishIntro" in ::rs_introFunc)
			::rs_introFunc.forceFinishIntro();
	}
	function startDelayedLocalRestore()
	{
		if(::rs_cp.pendingLocalRestore)
			return;

		::rs_cp.pendingLocalRestore = true;

		// 復元自体は8人が揃うまで待つが、イントロだけは先に解除する
		::rs_cp.tryIntroSkipOnce();

		local now = Time();

		::rs_cp.debugPrint(format(
			"Delayed local restore started. expected=%d",
			::rs_cp.localCheckpointSurvivorCount
		));

		::raya_timer.AddTimer(0.25, true, ::rs_cp.delayedLocalRestoreThink, {
			startTime = now,
			endTime = now + 12.0,
			minDelay = 4.0,
			expectedCount = ::rs_cp.localCheckpointSurvivorCount
		});
	}
	function delayedLocalRestoreThink(params)
	{
		local now = Time();
		local counts = ::rs_cp.countCurrentSurvivorsForDelayedRestore();
		local survCount = counts[0];
		local tempCount = counts[1];

		local minDelayDone = (now >= params.startTime + params.minDelay);
		local enoughSurvivors = (survCount >= params.expectedCount);
		local noTempClient = (tempCount <= 0);
		local timeout = (now >= params.endTime);

		if((minDelayDone && enoughSurvivors && noTempClient) || timeout){
			::rs_cp.pendingLocalRestore = false;

			::rs_cp.debugPrint(format(
				"Delayed local restore execute. survivors=%d/%d temp=%d timeout=%s",
				survCount,
				params.expectedCount,
				tempCount,
				timeout ? "true" : "false"
			));

			::rs_cp.tryRestoreCheckpoint();
			::rs_cp.isStartupLocalFileRestore = false;
			return false;
		}

		::rs_cp.debugPrint(format(
			"Waiting delayed local restore. survivors=%d/%d temp=%d",
			survCount,
			params.expectedCount,
			tempCount
		));

		return true;
	}
	
	function tryRestoreCheckpoint()
	{
		local gt_data = {};
		RestoreTable("rs_table", gt_data);

		// RestoreTable() で読み出した内容を消さないよう、すぐ戻しておく
		SaveTable("rs_table", gt_data);

		if("gametime" in gt_data && Director.GetTotalElapsedMissionTime() > gt_data["gametime"])
		{
			if("restoreOFF" in gt_data && gt_data["restoreOFF"]){
				::rs_cp.isRestoreOFF = true;
				::rs_cp_print.printLang("warning_stop_restore");
				return;
			}
			
			::rs_cp.tryIntroSkipOnce();
			
			local data_common = {}; RestoreTable("rs_common", data_common);
			local data_surv = {};   RestoreTable("rs_survivors", data_surv);

			local applied = ::rs_cp.restoreStockData(data_common, data_surv);
			
			if(applied && ::rs_cp.prohibitBehindTime > 0){
				::rs_cp.prohibitBehindStamp++;
				local stamp = ::rs_cp.prohibitBehindStamp;
				::rs_cp.markCurrentInfectedForProhibitBehind(stamp);

				::raya_timer.AddTimer(0.1, true, ::rs_cp.prohibitBehindInfectedTimer, { endTime = Time() + ::rs_cp.prohibitBehindTime, stamp = stamp });
			}
		}
	}
	function restoreStockData(data_common, data_surv)
	{
		if(data_surv != null && ("list" in data_surv) && data_common != null && data_common.len() > 0){
			::rs_cp.commonList = [];
			::rs_cp.survivorsList = [];
			::rs_cp.commonList.append(data_common);
			::rs_cp.survivorsList.append(data_surv.list);

			::rs_cp.lastFlow = data_common["flow"];
			::rs_cp.trulySaveFlow = data_common["flow"];
			::rs_cp.lastRestoreLibraryBucket = ::rs_cp.getRestoreLibraryBucket(data_common["flow"]);
			
			if(::rs_cp.debug){
				local restoredFlow = data_common["flow"].tofloat();
				local restoredLoadIntervalPercent = -1;
	
				if(::rs_cp.loadIntervalFlow > 0)
					restoredLoadIntervalPercent = (floor(restoredFlow / ::rs_cp.loadIntervalFlow) * ::rs_cp.loadIntervalFlow).tointeger();
	
				::rs_cp.debugPrint("\n" + format("Restore load interval: %d%%", restoredLoadIntervalPercent) + "\n"
					+ format("saved Flow: %.1f%%", restoredFlow) + "\n"
					+ format("loadIntervalFlow: %d%%", ::rs_cp.loadIntervalFlow));
			}

			::rs_cp.restoreDataCommon = data_common;
			::rs_cp.restoreDataSurv = data_surv;
			
			//::rs_cp.restoreUntilTime = Time() + 5.0;
			//::rs_cp.restoreStamp = UniqueString();
			//::rs_cp.restoreUsedRowIndexes = {};
			
			local restoreCount = 0;
			if(data_surv != null && ("list" in data_surv))
				restoreCount = data_surv.list.len();

			// +4人が遅れて生成される場合、長めに待つ
			::rs_cp.restoreUntilTime = Time() + ((restoreCount > 4) ? 12.0 : 5.0);
			::rs_cp.restoreStamp = UniqueString();
			::rs_cp.restoreUsedRowIndexes = {};

			local tp_pos = Vector(data_common["origin_x"], data_common["origin_y"], data_common["origin_z"]);
			if((tp_pos - ::rs_cp.initialPos).Length() > 500){
				local applied = false;

				for(local surv; surv = Entities.FindByClassname(surv, "player"); ){
					if(::rs_cp.restoreSingleSurvivor(surv))
						applied = true;
				}
				
				::raya_timer.AddTimer(0.3, true, ::rs_cp.restoreLateSurvivorsThink, {
					endTime = ::rs_cp.restoreUntilTime
				});

				return applied;
			}
			else
				::rs_cp.debugPrint(format("The distance between tp_pos and initialPos is too close. (dist: %.1f)", (tp_pos - ::rs_cp.initialPos).Length()));
		}
		else
			::rs_cp.debugPrint("The data received is corrupted or empty.");

		return false;
	}
	function restoreSingleSurvivor(surv)
	{
		if(surv == null || !surv.IsValid() || surv.GetZombieType() != 9)
			return false;

		if(::rs_cp.restoreUntilTime <= Time())
			return false;
		
		if(::rs_cp.isTemporaryL4LSurvivorClient(surv)){
			::rs_cp.debugPrint("\x03" + format("%s\x01 is temporary L4L survivor client. Skip restore.", surv.GetPlayerName()));
			return false;
		}

		if(::rs_cp.restoreDataCommon == null || ::rs_cp.restoreDataCommon.len() <= 0)
			return false;
		if(::rs_cp.restoreDataSurv == null || !("list" in ::rs_cp.restoreDataSurv))
			return false;

		local tp_pos = Vector(::rs_cp.restoreDataCommon["origin_x"], ::rs_cp.restoreDataCommon["origin_y"], ::rs_cp.restoreDataCommon["origin_z"]);
		if((tp_pos - ::rs_cp.initialPos).Length() <= 500)
			return false;
		
		surv.ValidateScriptScope();
		local scope = surv.GetScriptScope();

		if(("rs_cp_restoreStamp" in scope) && scope.rs_cp_restoreStamp == ::rs_cp.restoreStamp)
			return false;
		scope.rs_cp_restoreStamp <- ::rs_cp.restoreStamp;
		
		if(!IsPlayerABot(surv)){
			if(::rs_cp.restore_FadeOut) ::rs_cp.Effect_FadeScreen(surv, 0, 0, 0, 255, 1.0, 1.6, false, true);
			if(::rs_cp.restore_SndName != "") EmitAmbientSoundOn(::rs_cp.restore_SndName, 1.0, 350, 100, surv);
		}

		surv.SetOrigin(tp_pos);
		::raya_timer.AddTimer(0.5, true, ::rs_cp.retrySetOrigin, {
			surv = surv,
			tp_pos = tp_pos,
			thatTime = Time(),
			awayStartTime = null,
			stuckStartTime = null
		});
		NetProps.SetPropFloat(surv, "m_flLaggedMovementValue", 0.0);

		local scopeUID = ("SurvivorUID" in scope) ? scope.SurvivorUID : -1;
		local row = ::rs_cp.findRestoreRowForSurvivor(surv, scopeUID);

		if(row != null){
			// ゲーム再起動後などでUIDが消えていた場合、
			// 復元に使ったrowのUIDを現在のentityへ再付与する
			if("uid" in row)
				scope.SurvivorUID <- row.uid;

			::rs_cp.RestorePlayerAllInventory(surv, row.invdata);

			if(::rs_cp.restoreHP)
				::raya_timer.AddTimer(0.2, false, ::rs_cp.setHPTimer, {surv = surv, row = row});
		}
		else{
			::rs_cp.debugPrint(format("No restore row matched\x03 %s\x01. (UID: %d)", surv.GetPlayerName(), scopeUID));
		}

		return true;
	}
	function restoreLateSurvivorsThink(params)
	{
		if(Time() >= params.endTime)
			return false;

		if(::rs_cp.restoreUntilTime <= Time())
			return false;

		if(::rs_cp.restoreDataCommon == null || ::rs_cp.restoreDataCommon.len() <= 0)
			return false;

		if(::rs_cp.restoreDataSurv == null || !("list" in ::rs_cp.restoreDataSurv))
			return false;

		for(local surv; surv = Entities.FindByClassname(surv, "player"); ){
			if(surv == null || !surv.IsValid() || surv.GetZombieType() != 9)
				continue;

			// L4L の一時 fake client には触らない
			if(::rs_cp.isTemporaryL4LSurvivorClient(surv))
				continue;

			::rs_cp.restoreSingleSurvivor(surv);
		}

		return true;
	}
	function retrySetOrigin(params){
		local surv = params.surv;
		if(surv == null || !surv.IsValid())
			return false;
		
		local time = Time();
		
		if(IsPlayerABot(surv)) CommandABot({ cmd = 3, bot = surv });

		// 復元後にスタック状態が3秒続いた場合、近くの到達可能なnav地点へ移動する
		if(NetProps.GetPropInt(surv, "m_StuckLast") > 0){
			// スタック中は復元成功カウントを進めない
			params.awayStartTime = null;

			if(params.stuckStartTime == null){
				params.stuckStartTime = time;
			}
			else if(time >= params.stuckStartTime + 3.0){
				local pathable_pos = ::rs_cp.findPathableLocationForStuck(surv);

				if(pathable_pos != null){
					params.tp_pos = pathable_pos;
					params.awayStartTime = null;
					params.stuckStartTime = null;
					params.thatTime = time;

					surv.SetOrigin(params.tp_pos);
					::rs_cp.debugPrint("\x03" + format("%s\x01 was stuck. Moved to a pathable location.", surv.GetPlayerName()));
				}
				else{
					// 近くに有効地点が見つからなかった場合は、3秒後に再試行する
					params.stuckStartTime = time;
					::rs_cp.debugPrint("\x03" + format("%s\x01 was stuck, but no nearby pathable location was found.", surv.GetPlayerName()));
				}
			}

			return true;
		}
		else{
			params.stuckStartTime = null;
		}
		
		if((surv.GetOrigin() - ::rs_cp.initialPos).Length() > 500 && (surv.GetOrigin() - params.tp_pos).Length() <= 500){
			if(params.awayStartTime == null){
				params.awayStartTime = time;
			}
			else if(time >= params.awayStartTime + 1.0){
				NetProps.SetPropFloat(surv, "m_flLaggedMovementValue", 1.0);
				
				if(time >= params.awayStartTime + 3.0){
					::rs_cp.debugPrint("\x04" + format("%s has been successfully restored.", surv.GetPlayerName()));
					return false;
				}
			}
		}
		else{
			params.awayStartTime = null;
			surv.SetOrigin(params.tp_pos);
			::rs_cp.debugPrint("\x03" + format("%s\x01 still in safe area. Trying to restore...", surv.GetPlayerName()));
			
			// 12秒経ったら復元失敗
			if(time >= params.thatTime + 12.0){
				NetProps.SetPropFloat(surv, "m_flLaggedMovementValue", 1.0);
				::rs_cp_print.printLang("failed_restore", {playerName = surv.GetPlayerName()});
				return false;
			}
		}
	}
	function findPathableLocationForStuck(surv)
	{
		if(surv == null || !surv.IsValid())
			return null;

		local survPos = surv.GetOrigin();
		for(local radius = 64.0; radius <= 320.0; radius += 64.0){
			for(local i = 0; i < 8; i++){
				local pos = surv.TryGetPathableLocationWithin(radius);
				if(pos != null && (survPos - pos).Length() < 320.0)
					return pos + Vector(0, 0, 5);
			}
		}

		return null;
	}
	function setHPTimer(params){
		local surv = params.surv;
		local row = params.row;
		
		if(surv == null || !surv.IsValid())
			return;
		
		local hp = ("HP" in row) ? row["HP"] : surv.GetHealth();
		local hp_buff = ("HP_buff" in row) ? row["HP_buff"] : surv.GetHealthBuffer();

		if(row["is_active"]){
			surv.SetHealth(hp);
			surv.SetHealthBuffer(hp_buff);
		}
		else{
			hp = 1;
			hp_buff = 29.0;
			surv.SetHealth(hp);
			surv.SetHealthBuffer(hp_buff);
		}
		
		::rs_cp.debugPrint("\x03" + format("%s\x01: HP %d, tempHP %d", surv.GetPlayerName(), hp, hp_buff));

		if(::rs_cp.restoreHP_AtLeast >= 2){
			local total_hp = hp + hp_buff;

			switch(::rs_cp.restoreHP_Type){
				case 0: {
					if(total_hp < ::rs_cp.restoreHP_AtLeast){
						hp += (::rs_cp.restoreHP_AtLeast - total_hp);
						::rs_cp.debugPrint("\x03" + format("%s\x01's total HP was below %d. HP has been adjusted.", surv.GetPlayerName(), ::rs_cp.restoreHP_AtLeast));
					}
					break;
				}
				case 1: {
					if(total_hp < ::rs_cp.restoreHP_AtLeast){
						hp_buff += (::rs_cp.restoreHP_AtLeast - total_hp);
						::rs_cp.debugPrint("\x03" + format("%s\x01's total HP was below %d. temp HP has been adjusted.", surv.GetPlayerName(), ::rs_cp.restoreHP_AtLeast));
					}
					break;
				}
				case 2: {
					if(hp < ::rs_cp.restoreHP_AtLeast){
						hp += (::rs_cp.restoreHP_AtLeast - hp);
						::rs_cp.debugPrint("\x03" + format("%s\x01's real HP was below %d. HP has been adjusted.", surv.GetPlayerName(), ::rs_cp.restoreHP_AtLeast));
					}
					break;
				}
				case 3: {
					if(hp < ::rs_cp.restoreHP_AtLeast){
						hp_buff = total_hp - ::rs_cp.restoreHP_AtLeast;
						if(hp_buff < 0)
							hp_buff = 0.0;

						hp = ::rs_cp.restoreHP_AtLeast;
						::rs_cp.debugPrint("\x03" + format("%s\x01's real HP was below %d. HP has been adjusted and temp HP has been reduced.", surv.GetPlayerName(), ::rs_cp.restoreHP_AtLeast));
					}
					break;
				}
			}

			local max_hp = surv.GetMaxHealth();
			local new_total = hp + hp_buff;

			if(new_total > max_hp){
				hp_buff -= (new_total - max_hp);
				if(hp_buff < 0){
					hp += hp_buff;
					hp_buff = 0.0;
				}
			}

			if(hp < 1)		hp = 1;
			if(hp > max_hp)	hp = max_hp;
			
			surv.SetHealth(hp);
			surv.SetHealthBuffer(hp_buff);
		}
	}
	function markCurrentInfectedForProhibitBehind(stamp)
	{
		for(local infected; infected = Entities.FindByClassname(infected, "infected"); ){
			if(!infected.IsValid() || NetProps.GetPropInt(infected, "m_lifeState") != 0)
				continue;

			infected.ValidateScriptScope();
			infected.GetScriptScope().rs_cp_prohibitBehindStamp <- stamp;
		}
	}
	function prohibitBehindInfectedTimer(params)
	{
		if(Time() >= params.endTime)
			return false;
		
		local survMinFlow = null;
		for(local surv; surv = Entities.FindByClassname(surv, "player"); ){
			if(!surv.IsValid() || !surv.IsSurvivor() || surv.IsDead() || surv.IsDying())
				continue;

			local survFlow = GetCurrentFlowDistanceForPlayer(surv);
			if(survFlow < 0)
				continue;

			if(survMinFlow == null || survFlow < survMinFlow)
				survMinFlow = survFlow;
		}

		if(survMinFlow != null)
		{
			for(local infected; infected = Entities.FindByClassname(infected, "infected"); ){
				if(!infected.IsValid() || NetProps.GetPropInt(infected, "m_lifeState") != 0)
					continue;

				infected.ValidateScriptScope();
				local scope = infected.GetScriptScope();

				// 復元時点で既にいたCI、またはこのタイマー中に一度判定済みのCIは無視
				if(("rs_cp_prohibitBehindStamp" in scope) && scope.rs_cp_prohibitBehindStamp == params.stamp)
					continue;

				local infectedFlow = GetFlowDistanceForPosition(infected.GetOrigin());

				// 「この復元処理に対しては判定済み」として印を付ける
				scope.rs_cp_prohibitBehindStamp <- params.stamp;

				// 初回検出時の位置が、生存者最後尾より後ろならKill
				if(infectedFlow >= 0 && infectedFlow < survMinFlow && Director.IsTankInPlay()){
					//ClientPrint(null, 3, format("time: %.2f, survF: %.1f, infF: %.1f", Time(), survMinFlow, infectedFlow));
					infected.Kill();
				}
			}
		}
	}
	
	//function OnGameEvent_explain_panic_button(params){ ::rs_cp.event_params_check(params, "panic_button"); } //c8m2 ホード前✘ (create_panic_event発動)
	
	function OnGameEvent_finale_vehicle_incoming(params){ ::rs_cp.isRoundEnd = true; }
	function OnGameEvent_explain_gun_shop(params){ //start c1m2 gun_shop入ったら
		if(::rs_cp.s_MapName.find("c1m2_streets") != null){		::rs_cp.isForceStopSave = true; ::rs_cp.debugPrint("\x04" + "'isForceStopSave' set to true. gun_shop"); }
	}
	function OnGameEvent_explain_store_item_stop(params){ // end c1m2 コーラ届けたら
		if(::rs_cp.s_MapName.find("c1m2_streets") != null){		::rs_cp.isForceStopSave = false; ::rs_cp.debugPrint("\x04" + "'isForceStopSave' set to false. store_item_stop"); }
	}
	function OnGameEvent_explain_mall_alarm(params){ //start c1m3 end無し
		if(::rs_cp.s_MapName.find("c1m3_mall") != null){			::rs_cp.isForceStopSave = false; ::rs_cp.debugPrint("\x04" + "'isForceStopSave' set to false. mall_alarm"); }
	}
	function OnGameEvent_explain_carousel_destination(params){ //start c2m2 end無し
		if(::rs_cp.s_MapName.find("c2m2_fairgrounds") != null){		::rs_cp.isPanicEvent = 30.0; ::rs_cp.debugPrint("\x04" + "Panic Event triggered. carousel_destination"); }
	}
	function OnGameEvent_explain_coaster_stop(params){ //start c2m3 end無し ゴールまでNoSave
		if(::rs_cp.s_MapName.find("c2m3_coaster") != null){		::rs_cp.isRoundEnd = true; ::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated. coaster_stop"); }
	}
	function OnGameEvent_explain_c2m4_ticketbooth(params){ //start c2m4 ホード前 ゴールまでNoSave
		if(::rs_cp.s_MapName.find("c2m4_barns") != null){			::rs_cp.isRoundEnd = true; ::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated. c2m4_ticketbooth"); }
	}
	function OnGameEvent_explain_perimeter(params){ //start c5m2
		if(::rs_cp.s_MapName.find("c5m2_park") != null){			::rs_cp.isPanicEvent = 60.0; ::rs_cp.debugPrint("\x04" + "Panic Event triggered. perimeter"); }
	}
	function OnGameEvent_explain_drawbridge(params){ //start c5m5 橋前 ゴールまでNoSave
		if(::rs_cp.s_MapName.find("c5m5_bridge") != null){			::rs_cp.isRoundEnd = true; ::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated. drawbridge"); }
	}
	function OnGameEvent_explain_mainstreet(params){ //start c10m4 ホード前 ゴールまでNoSave
		if(::rs_cp.s_MapName.find("c10m4_mainstreet") != null){		::rs_cp.isRoundEnd = true; ::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated. mainstreet"); }
	}
	function OnGameEvent_explain_train_lever(params){ //start c12m3 ホード前 ゴールまでNoSave
		if(::rs_cp.s_MapName.find("c12m3_bridge") != null){		::rs_cp.isRoundEnd = true; ::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated. train_lever"); }
	}
	
	function OnGameEvent_create_panic_event(params){
		if(::rs_cp.s_MapName == "c6m2_bedlam"){
			::rs_cp.isRoundEnd = true;
			::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated. c6m2_bedlam");
		} else {
			::rs_cp.isPanicEvent = 60.0;
			::rs_cp.debugPrint("\x04" + "create_panic_event executed.");
		}
	}
	//発動: c3m1(115s) c3m2(60s) c3m3(60s) c4m2(70s) c5m4(60s) c6m1 c6m2 c7m1 c7m2 c8m2 c8m3(20s) c8m4 c9m1 c10m2 c10m3 c11m2 c11m3 c12m2 c13m1 c13m3 c14m1
	
	
	function event_params_check(params, event_name){
		local msg = "Event: "+event_name;
		if("userid" in params){
			local player = GetPlayerFromUserID(params.userid);
			if(player != null && player.IsValid()) msg = format("%s, username %s", msg, player.GetPlayerName());
		}
		if("subject" in params){
			local ent = EntIndexToHScript(params["subject"]);
			msg = format("%s, subject %s", msg, ent.GetClassname());
		}
		
		::rs_cp.debugPrint(msg);
	}
	
	
	function OnGameEvent_map_transition(params){
		::rs_cp.isRoundEnd = true;
		
		::rs_cp.clearLocalMapData();
		
		SaveTable("rs_table", {});
		SaveTable("rs_common", {});
		SaveTable("rs_survivors", {});
		SaveTable("rs_history", {});
	}
	function OnGameEvent_finale_win(params){
		::rs_cp.isRoundEnd = true;

		::rs_cp.clearLocalMapData();

		SaveTable("rs_table", {});
		SaveTable("rs_common", {});
		SaveTable("rs_survivors", {});
		SaveTable("rs_history", {});
	}
	function OnGameEvent_mission_lost(params){
		::rs_cp.isRoundEnd = true;
		
		local gt_data = {};
		RestoreTable("rs_table", gt_data);
		gt_data["gametime"] <- Director.GetTotalElapsedMissionTime();
		SaveTable("rs_table", gt_data);
		::rs_cp.debugPrint(format("Total rounds gametime: %.1f", gt_data["gametime"]));
		
		::rs_cp.stockCurrentRoundToRestoreLibrary();
		
		if(::rs_cp.trulySaveFlow > 0 && ::rs_cp.commonList.len() > 0)
		{
			local index = ::rs_cp.commonList.len() - 1;
			foreach(i, value in ::rs_cp.commonList){
				if(value["flow"] >= ::rs_cp.trulySaveFlow){
					index = i;
					break;
				}
			}

			// アドオンマップのみ:
			// パニックイベント中に全滅した場合は、 flow が ～%以上低い地点を探す
			if(!::rs_cp.isFinaleStart && !::rs_cp.isOfficialMap() && (::rs_cp.isPanicEvent > 0.0 || ::rs_cp.isHordeNow())){
				if(::rs_cp.hordeBehindFlow >= 1){
					local base_flow = ("flow" in ::rs_cp.commonList[index]) ? ::rs_cp.commonList[index].flow : ::rs_cp.trulySaveFlow;
	
					for(local i = ::rs_cp.commonList.len()-1; i >= 0; i--){
						local value = ::rs_cp.commonList[i];
						if(value["flow"] <= base_flow - ::rs_cp.hordeBehindFlow){
							index = i;
							break;
						}
					}
				}
			}

			// common 側の防御
			if(index < 0) index = 0;
			else if(index >= ::rs_cp.commonList.len())
				index = ::rs_cp.commonList.len() - 1;

			local save_data = ::rs_cp.commonList[ index ];
			SaveTable("rs_common", save_data);

			// survivors 側の防御:
			// common の index が無ければ最後の要素を使う
			local surv_index = index;
			if(::rs_cp.survivorsList.len() <= 0){
				SaveTable("rs_survivors", {});
				::rs_cp.debugPrint("survivorsList is empty.");
				return;
			}
			if(surv_index >= ::rs_cp.survivorsList.len())
				surv_index = ::rs_cp.survivorsList.len() - 1;
			if(surv_index < 0)
				surv_index = 0;

			local get_list = ::rs_cp.survivorsList[ surv_index ];
			if(get_list == null)
				get_list = [];

			SaveTable("rs_survivors", {list = get_list});
			
			if(::rs_cp.exportLocalFile)
				::rs_cp.saveLocalMapData(save_data, get_list);
			
			if(::rs_cp.announce_Restore && !::rs_cp.isRestoreOFF)
				::rs_cp_print.printLang("restart_checkpoint");
		}
	}
	
	
	function OnGameEvent_player_left_safe_area(params){
		if(::rs_cp.pendingLocalRestore){
			::rs_cp.debugPrint("Ignore player_left_safe_area while waiting delayed local restore.");
			return;
		}
		
		if(::rs_cp.restoreTiming == 2)
			::rs_cp.tryRestoreCheckpoint();
		
		::rs_cp.debugPrint("\x04" + "Player left safe area, Starting save timer.");
		::raya_timer.AddTimer(5, false, ::rs_cp.saveSurvivorsDataTimerSet, {});
		
		if(::rs_cp.isRestoreOFF)
			::rs_cp_print.printLang("disabled_notice");

		if(::rs_cp.isVersionDifferent){
			::rs_cp_print.printLang("settings_reset_notice");
			::rs_cp.isVersionDifferent = false;
		}
		
		if(::rs_cp.settingsLoadWarnings.len() > 0){
			local host = ::rs_cp.getAdmin();
			if(host != null){
				ClientPrint(host, 3, "\x05" + "[Restore Checkpoint System]");
				foreach(msg in ::rs_cp.settingsLoadWarnings)
					ClientPrint(host, 3, format("\x04[WARNING]\x01 %s", msg));

				::rs_cp.settingsLoadWarnings = [];
				
				EmitAmbientSoundOn("Instructor.ImportantLessonStart", 1.0, 550, 70, host);
			}
		}
	}
	function saveSurvivorsDataTimerSet(params)
	{
		local dummy = SpawnEntityFromTable("logic_script", {});
		dummy.ValidateScriptScope();
		dummy.GetScriptScope().saveSurvivorsDataThink <- function()
		{	
			if(::rs_cp.isRoundEnd || ::rs_cp.isFinaleStart){
				self.Kill();
				return 1;
			}
			
			if(::rs_cp.isForceStopSave){
				::rs_cp.debugPrint("\x04" + "No saving because 'isForceStopSave' is true.");
				return ::rs_cp.thinkInterval;
			}
			if(::rs_cp.isAlarmSoundPlaying()){
				::rs_cp.debugPrint("\x04" + "No saving while Alarm is playing.");
				return ::rs_cp.thinkInterval;
			}
			if(::rs_cp.noSave_DuringTankInPlay && Director.IsTankInPlay()){
				::rs_cp.debugPrint("\x04" + "No saving during Tanks are active.");
				return ::rs_cp.thinkInterval;
			}
			
			local is_horde = ::rs_cp.isHordeNow();
			
			// パニックイベント中でも is_hordeがfalseになることがあるため、すぐにホード判定を切ってホード中にセーブされてしまわないように。
			if(is_horde){
				// create_panic_eventで設定した秒数は減らしていって、あとは disablePanicDelay で判定
				if(::rs_cp.isPanicEvent <= ::rs_cp.disablePanicDelay) ::rs_cp.isPanicEvent = ::rs_cp.disablePanicDelay;
				else ::rs_cp.isPanicEvent -= ::rs_cp.thinkInterval;
			}
			else
				::rs_cp.isPanicEvent -= ::rs_cp.thinkInterval;

			if(::rs_cp.isPanicEvent < 0.0)
				::rs_cp.isPanicEvent = 0.0;
			
			if(is_horde || ::rs_cp.isPanicEvent > 0.0){
				::rs_cp.debugPrint("\x04" + format("No saving during Panic Event. | left: %.1f", ::rs_cp.isPanicEvent));
				return ::rs_cp.thinkInterval;
			}
			
			local standSurvData = ::rs_cp.getSurvivorStandFlow();
			local owner = standSurvData[0];
			local stand_pos = standSurvData[1];
			local stand_flow = standSurvData[2];
			
			if(owner == null)	::rs_cp.debugPrint("Error: No candidates were found.");
			if(stand_flow <= -1)	::rs_cp.debugPrint("Error: Failed to get Flow.");
			
			// マップによって強制終了 (create_panic_eventが発動しないため)
			if( (::rs_cp.s_MapName == "c1m3_mall" && stand_flow >= 43) //43% (パニックイベントを起こさないとセーフルームへの道が出現しない)
				|| (::rs_cp.s_MapName == "c1m4_atrium" && stand_flow >= 67) //67%(3200) (エレベーター中でトリガー)
				|| (::rs_cp.s_MapName == "c5m3_cemetery" && stand_flow >= 65 && stand_pos.z < 200) //65% (墓地の地形が変わるため)
				|| (::rs_cp.s_MapName == "c6m3_port" && stand_flow >= 85) //85%(3700) (エレベーター中でトリガー)
				|| (::rs_cp.s_MapName == "c11m4_terminal" && stand_flow >= 68) //68%(12762) (ゲート前)
				|| (::rs_cp.s_MapName == "c13m2_southpinestream" && stand_flow >= 76) //76%(20246)
				|| (::rs_cp.s_MapName == "c13m3_memorialbridge" && stand_flow >= 80) //80%(19680)
			){ 
				::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated.");
				self.Kill();
				return 1;
			}
			// noSave_AfterFlow以降 強制終了
			if(::rs_cp.noSave_AfterFlow >= 1 && stand_flow >= ::rs_cp.noSave_AfterFlow){
				::rs_cp.debugPrint("\x04" + "Save Timer Force-Terminated: Flow reached noSave_AfterFlow.");
				self.Kill();
				return 1;
			}
			
			if(owner != null && stand_flow >= ::rs_cp.lastFlow+::rs_cp.stockFlow) // stockFlow%ずつストック
			{
				local table = {};
				local restorePos = stand_pos;
				table["origin_x"] <- restorePos.x;
				table["origin_y"] <- restorePos.y;
				table["origin_z"] <- restorePos.z;
				table["flow"] <- stand_flow;
				::rs_cp.commonList.append(table); //ストックしていく
		
				local list = [];
				for(local surv; surv = Entities.FindByClassname(surv, "player"); ){
					if(!surv.IsValid() || surv.GetZombieType() != 9)
						continue;
					
					local uid = ::rs_cp.EnsureSurvivorUID(surv);
					if(uid == null)
						continue;
		
					local row = {};
					row["uid"] <- uid;
					
					if(::rs_cp.exportLocalFile){
						row["character"] <- ::rs_cp.getSurvivorCharacter(surv);
						row["networkid"] <- ::rs_cp.getSurvivorNetworkID(surv);
					}
					
					row["HP"] <- surv.GetHealth();
					row["HP_buff"] <- surv.GetHealthBuffer();
					row["is_active"] <- (!surv.IsIncapacitated() && !surv.IsDead() && !surv.IsDying() && !surv.IsHangingFromLedge());
					row["invdata"] <- ::rs_cp.GetPlayerAllInventory(surv);
					list.append(row);
				}
				::rs_cp.survivorsList.append(list); //ストックしていく
				
				/*
				common = [
					{origin_x = 0.0, },
					{},
					{}
				]
				
				survs = [
					[{uid = 0, inventory = ""}, {}, {}],
					[],
					[]
				]
				*/
				
				::rs_cp.lastFlow = stand_flow;
				
				local playerName = (IsPlayerABot(owner)) ? owner.GetPlayerName()+" (Bot)" : owner.GetPlayerName();
				::rs_cp.debugPrint(format("Data Stock: (Position: %s) (%.1f%%)", playerName, stand_flow));
				
				if(stand_flow >= ::rs_cp.trulySaveFlow + ::rs_cp.loadIntervalFlow){
					::rs_cp.trulySaveFlow = stand_flow;
					::rs_cp.debugPrint("\x04" + format("Checkpoint saved: (Position: %s) (%.1f%%)", playerName, stand_flow));
					if(::rs_cp.announce_Save >= 1){
						//::rs_cp_print.printLang("checkpoint_saved", {playerName = playerName, stand_flow = stand_flow});
						::rs_cp_print.printLang("checkpoint_saved");
						if(::rs_cp.announce_Save == 2) ::rs_cp.emitAmbientSoundOnAll(::rs_cp.announce_Save_SndName);
					}
				}
				
				if(::rs_cp.exportLocalFile)
					::rs_cp.saveLocalMapData();
			}
			
			return ::rs_cp.thinkInterval;
		}
		AddThinkToEnt(dummy, "saveSurvivorsDataThink");
	}
	
	
	function OnGameEvent_player_say(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if(player != ::rs_cp.getAdmin())
			return;
		
		local chat = params.text.tolower();
		
		local arr = split(chat," ");
		local chatlen = arr.len(); //空白で区切った文字列の数
		if(chatlen <= 0) return;
		
		if(arr[0] == "!rscp" || arr[0] == "/rscp"){
			if(chatlen < 2){
				ClientPrint(player, 3, "!rscp [off/on/list/restore/debug/ex or exp]");
				// "off = このチャプターのみ復元を無効化する。
				// "on = このチャプターの復元を有効化する。
				// "list = このチャプターの復元ライブラリを一覧表示する。
				// "restore previous = 1つ前の復元地点に復元する。
				// "restore <flow> = 指定flow以下で最も近い復元地点に復元する。
				// "debug" = debugを切り替える
				// "ex"or"exp" = exportLocalFileを切り替える
				return;
			}
			
			if(arr[1] == "off"){
				local gt_data = {};
				RestoreTable("rs_table", gt_data);
				gt_data["restoreOFF"] <- true;
				SaveTable("rs_table", gt_data);
				::rs_cp.isRestoreOFF = true;
				::rs_cp_print.printLang("restore_off");
				return;
			}
			if(arr[1] == "on"){
				local gt_data = {};
				RestoreTable("rs_table", gt_data);
				gt_data["restoreOFF"] <- false;
				SaveTable("rs_table", gt_data);
				::rs_cp.isRestoreOFF = false;
				::rs_cp_print.printLang("restore_on");
				return;
			}
			if(arr[1] == "list"){
				local history_list = ::rs_cp.getRestoreLibraryList();
				if(history_list.len() <= 0){
					ClientPrint(player, 3, "Restore Library: empty");
					return;
				}

				local bucket_list = [];
				foreach(entry in history_list){
					if(!("bucketFlow" in entry))
						continue;

					local inserted = false;
					for(local i = 0; i < bucket_list.len(); i++){
						if(entry.bucketFlow < bucket_list[i]){
							bucket_list.insert(i, entry.bucketFlow);
							inserted = true;
							break;
						}
					}
					if(!inserted)
						bucket_list.append(entry.bucketFlow);
				}

				local text = "\x01" + "Restore Library:";
				foreach(bucket in bucket_list){
					local adds = (bucket == ::rs_cp.lastRestoreLibraryBucket) ? "\x04"+bucket+"*"+"\x01" : bucket;
					text += " " + adds;
				}
				ClientPrint(player, 3, text);
				return;
			}
			if(arr[1] == "restore"){ //手動で復元
				if(chatlen < 3){
					ClientPrint(player, 3, "!rscp restore [previous/<flow>]");
					return;
				}

				local target_bucket = -1;

				if(arr[2] == "previous"){
					if(::rs_cp.lastRestoreLibraryBucket < 0){
						ClientPrint(player, 3, "No previous restore point.");
						return;
					}

					target_bucket = ::rs_cp.findPreviousRestoreLibraryBucket(::rs_cp.lastRestoreLibraryBucket);
					if(target_bucket < 0){
						ClientPrint(player, 3, "No previous restore point.");
						return;
					}
				}
				else{
					try{
						local target_flow = arr[2].tofloat();
						target_bucket = ::rs_cp.findRestoreLibraryBucketByFlow(target_flow);
					}
					catch(e){
						ClientPrint(player, 3, "!rscp restore [previous/<flow>]");
						return;
					}

					if(target_bucket < 0){
						ClientPrint(player, 3, "No restore point found.");
						return;
					}
				}

				if(::rs_cp.restoreFromLibraryBucket(target_bucket))
					ClientPrint(player, 3, format("Restored to Flow %.1f", target_bucket.tofloat()));
				else
					ClientPrint(player, 3, "Restore failed.");

				return;
			}
			if(arr[1] == "debug"){
				::rs_cp.debug = !::rs_cp.debug;
				::rs_cp.switch_key_setting("debug");

				ClientPrint(player, 3, "\x04" + format("[ToAdmin] debug = %s", (::rs_cp.debug ? "true" : "false")));

				if(::rs_cp.debug)
					::rs_cp.debugPrint("Debug mode enabled.");

				return;
			}
			if(arr[1] == "ex" || arr[1] == "exp"){
				::rs_cp.exportLocalFile = !::rs_cp.exportLocalFile;
				::rs_cp.switch_key_setting("exportLocalFile");

				ClientPrint(player, 3, "\x04" + format("[ToAdmin] exportLocalFile = %s", (::rs_cp.exportLocalFile ? "true" : "false")));

				if(::rs_cp.exportLocalFile)
					::rs_cp.debugPrint("Export to local files enabled.");

				return;
			}
		}
		/*if(arr[0] == "!getiv"){
			local inventoryData = ::rs_cp.GetPlayerAllInventory(player);
			
			local data = {};
            data.list <- [];
			local row = {};
			row["invdata"] <- inventoryData;
			data.list.append(row);
			SaveTable("rs_survivors", data);

			foreach (slotName, itemData in inventoryData)
			{
				if (itemData == null || itemData.len() == 0)
				{
					ClientPrint(player, 3, slotName + " = empty");
					continue;
				}

				foreach (key, value in itemData)
				{
					ClientPrint(player, 3, slotName + "." + key + " = " + value);
				}
			}
		}
		if(arr[0] == "!resiv"){
			local data = {};
			RestoreTable("rs_survivors", data);
			if (data == null || !("list" in data))
				return;

			foreach (row in data.list){
				::rs_cp.RestorePlayerAllInventory(player, row.invdata);
			}
		}
		*/
	}
	
	// 人間がいれば人間プレイヤーの中で決め、人間がいなければBotの中で決める
	function getSurvivorStandFlow()
	{
		local human_client = null;
		local bot_client = null;
		local human_flow = -1;
		local bot_flow = -1;
		local human_pos = Vector(0,0,0);
		local bot_pos = Vector(0,0,0);

		for(local surv; surv = Entities.FindByClassname(surv, "player");){
			if(!surv.IsValid() || surv.IsDead() || surv.IsDying() || surv.GetZombieType() != 9 || ::rs_cp.IsSurvivorInCheckpoint(surv))
				continue;
			
			local playerName = surv.GetPlayerName();
			if(NetProps.GetPropInt(surv, "m_StuckLast") > 0){
				::rs_cp.debugPrint("m_StuckLast | " + playerName);
				continue;
			}
			
			if(surv.IsHangingFromLedge()){
				::rs_cp.debugPrint("Hanging | " + playerName);
				continue;
			}
			
			if(::rs_cp.exclude_IncapSurv && surv.IsIncapacitated()){
				//::rs_cp.debugPrint("Incapacitated | " + playerName);
				continue;
			}
			
			if(::rs_cp.exclude_DominatedSurv && surv.IsDominatedBySpecialInfected()){
				//::rs_cp.debugPrint("Dominated | " + playerName);
				continue;
			}
			
			local movetype = NetProps.GetPropInt(surv, "movetype");
			if(movetype == 4 || movetype == 8 || movetype == 9){
				local movetype_name = "FLY";
				if(movetype == 8) movetype_name = "NOCLIP";
				else if(movetype == 9) movetype_name = "LADDER";
				::rs_cp.debugPrint(format("movetype: %s | %s", movetype_name, playerName));
				continue;
			}
			
			local origin = surv.GetOrigin();
			local head_pos = origin + Vector(0, 0, 73); // 頭の位置から足元方向へTraceする
			local new_pos = ::rs_cp.getGroundPosition(surv, head_pos);
			if(!new_pos){ //startsolid
				::rs_cp.debugPrint("Low height | " + playerName);
				continue;
			}
			// 床すり抜け時は、床取得失敗として現在位置を使う
			if(fabs(head_pos.z - new_pos.z) > 2000){
				new_pos = origin;
			}

			if(!::rs_cp.isValidNavPos(new_pos, playerName))
				continue;
			
			local fl = GetCurrentFlowPercentForPlayer(surv);
			//local fl2 = GetFlowPercentForPosition(new_pos, false);
			//ClientPrint(null,3,format("Flow %d, %.1f", fl, fl2));

			if(IsPlayerABot(surv)){
				if(fl > bot_flow){
					bot_flow = fl;
					bot_client = surv;
					bot_pos = new_pos;
				}
			}
			else{
				if(fl > human_flow){
					human_flow = fl;
					human_client = surv;
					human_pos = new_pos;
				}
			}
		}

		if(human_client != null)
			return [human_client, human_pos, human_flow];

		return [bot_client, bot_pos, bot_flow];
	}
	function isValidNavPos(pos, playerName)
	{
		local area = NavMesh.GetNavArea(pos, 120.0);
		if(area == null)
			area = NavMesh.GetNearestNavArea(pos, 200.0, false, true);
		if(area == null || !area.IsValid()){
			::rs_cp.debugPrint("Nav: area null | " + playerName);
			return false;
		}

		local dz = fabs(pos.z - area.GetZ(pos));
		if(dz > 512.0){
			::rs_cp.debugPrint("Nav: z mismatch | " + playerName);
			return false;
		}

		if(area.IsDegenerate()){
			::rs_cp.debugPrint("Nav: degenerate | " + playerName);
			return false;
		}

		local acid = Entities.FindByClassnameWithin(null, "insect_swarm", pos, 220.0);
		if(area.IsDamaging() && acid == null){
			::rs_cp.debugPrint("Nav: damaging | " + playerName);
			return false;
		}

		if(area.IsUnderwater()){
			::rs_cp.debugPrint("Nav: underwater | " + playerName);
			return false;
		}

		if(area.IsBlocked(2, true)){
			::rs_cp.debugPrint("Nav: blocked | " + playerName);
			return false;
		}

		if(area.HasAvoidanceObstacle(72.0)){
			::rs_cp.debugPrint("Nav: avoidance obstacle | " + playerName);
			return false;
		}

		if(area.HasAttributes(1073741824)){ // NAV_MESH_HAS_ELEVATOR
			::rs_cp.debugPrint("Nav: HAS_ELEVATOR | " + playerName);
			return false;
		}

		if(area.HasAttributes(128)){ // AVOID
			::rs_cp.debugPrint("Nav: AVOID | " + playerName);
			return false;
		}

		if(area.HasAttributes(32768)){ // CLIFF
			::rs_cp.debugPrint("Nav: CLIFF | " + playerName);
			return false;
		}

		if(area.HasAttributes(256)){ // TRANSIENT
			::rs_cp.debugPrint("Nav: TRANSIENT | " + playerName);
			return false;
		}

		if(area.HasAttributes(16)){ // STOP
			::rs_cp.debugPrint("Nav: STOP | " + playerName);
			return false;
		}

		if(area.HasAttributes(16384)){ // OBSTACLE_TOP
			::rs_cp.debugPrint("Nav: OBSTACLE_TOP | " + playerName);
			return false;
		}

		if(area.HasAttributes(134217728)){ // NAV_MESH_FLOW_BLOCKED
			::rs_cp.debugPrint("Nav: FLOW_BLOCKED | " + playerName);
			return false;
		}

		if(area.HasAttributes(268435456)){ // NAV_MESH_OUTSIDE_WORLD
			::rs_cp.debugPrint("Nav: OUTSIDE_WORLD | " + playerName);
			return false;
		}

		if(area.HasAttributes(-2147483648)){ // NAV_MESH_NAV_BLOCKER
			::rs_cp.debugPrint("Nav: NAV_BLOCKER | " + playerName);
			return false;
		}

		return true;
	}
	function getGroundPosition(player, origin)
	{
		local end_pos = origin + Vector(0, 0, -10000);
		local m_trace = { start = origin, end = end_pos, ignore = player, mask = 33636363 };
		TraceLine(m_trace);
		
		// (frac = 0.0, startsolid = true) は人と重なっている
		if(("fraction" in m_trace) && m_trace.fraction > 0.0 && ("startsolid" in m_trace) && m_trace.startsolid){
			return false;
		}
		
		return m_trace.pos;
	}
	
	// ダウン中は取得できるが、死亡中は取得できない。
	function GetPlayerAllInventory(player)
	{
		local savedData = {
			slot0 = {},
			slot1 = {},
			slot2 = {},
			slot3 = {},
			slot4 = {},
			slot5 = {},
			Held = {}
		};

		local inventoryTable = {};
		GetInvTable(player, inventoryTable);

		foreach (slotName, itemEntity in inventoryTable) {
			if(!itemEntity)
				continue;
			
			if(!(slotName in savedData))
				continue;

			local itemData = {};
			itemData.classname <- itemEntity.GetClassname();

			if (slotName == "slot0" || slotName == "slot1") {
				itemData.clip <- itemEntity.Clip1();
				
				if (slotName == "slot0") {
					itemData.ammo_type <- NetProps.GetPropInt(itemEntity, "m_iPrimaryAmmoType");
					itemData.ammo <- NetProps.GetPropIntArray(player, "m_iAmmo", itemData.ammo_type);
					itemData.upgrade_bits <- NetProps.GetPropInt(itemEntity, "m_upgradeBitVec");
					itemData.upg_am <- NetProps.GetPropInt(itemEntity, "m_nUpgradedPrimaryAmmoLoaded");
				}

				if (slotName == "slot1") {
					if (itemData.classname == "weapon_pistol") {
						itemData.is_dual <- NetProps.GetPropInt(itemEntity, "m_hasDualWeapons");
					}
					else if (itemData.classname == "weapon_melee") {
						local melee_name = NetProps.GetPropString(itemEntity, "m_strMapSetScriptName");
						itemData.melee_script_name <- (melee_name != null) ? melee_name : "";
					}
				}
			}

			savedData[slotName] = itemData;
		}

		return savedData;
	}
	function RestorePlayerAllInventory(player, savedData)
	{
		local currentInventory = {};
		GetInvTable(player, currentInventory);

		foreach (slotName, itemEntity in currentInventory) {
			if(itemEntity)
				itemEntity.Kill();
		}
		//同時に処理すると、GiveItemで渡したアイテムまでKillしてしまうので、遅延
		::raya_timer.AddTimer(0.01, false, ::rs_cp.RestorePlayerAllInventory_Delay, {player = player, savedData = savedData} );
	}
	function RestorePlayerAllInventory_Delay(params)
	{
		local player = params.player;
		local savedData = params.savedData;
		
		//デバッグ用
		/*foreach (slotName, itemData in savedData)
		{
			if (itemData == null || itemData.len() == 0)
			{
				ClientPrint(player, 3, slotName + " = empty");
				continue;
			}

			foreach (key, value in itemData)
			{
				ClientPrint(player, 3, slotName + "." + key + " = " + value);
			}
		}*/
		
		local is_slot0_ok = true;
		local is_slot1_ok = true;

		if("slot0" in savedData && savedData.slot0.len() > 0)
			player.GiveItem(savedData.slot0.classname);
		else
			is_slot0_ok = false;

		if("slot1" in savedData && savedData.slot1.len() > 0) {
			if (savedData.slot1.classname == "weapon_melee") {
				if ("melee_script_name" in savedData.slot1 && savedData.slot1.melee_script_name != "") {
					player.GiveItem(savedData.slot1.melee_script_name);
				}
				else {
					player.GiveItem("weapon_melee");
				}
			}
			else {
				player.GiveItem(savedData.slot1.classname);

				if (savedData.slot1.classname == "weapon_pistol" && ("is_dual" in savedData.slot1) && savedData.slot1.is_dual) {
					player.GiveItem("weapon_pistol");
				}
			}
		}
		else
			is_slot1_ok = false;
		

		if("slot2" in savedData && savedData.slot2.len() > 0)
			player.GiveItem(savedData.slot2.classname);

		if("slot3" in savedData && savedData.slot3.len() > 0)
			player.GiveItem(savedData.slot3.classname);
		
		if("slot4" in savedData && savedData.slot4.len() > 0)
			player.GiveItem(savedData.slot4.classname);

		if("slot5" in savedData && savedData.slot5.len() > 0)
			player.GiveItem(savedData.slot5.classname);

		// 該当スロットがカラの場合、武器を渡す
		if(::rs_cp.giveWepapon_AtLeast > 0){
			local currentInv = {};
			GetInvTable(player, currentInv);

			local has_slot0 = ("slot0" in currentInv) && currentInv.slot0;
			local has_slot1 = ("slot1" in currentInv) && currentInv.slot1;
			local has_slot2 = ("slot2" in currentInv) && currentInv.slot2;
			local has_slot3 = ("slot3" in currentInv) && currentInv.slot3;
			local has_slot4 = ("slot4" in currentInv) && currentInv.slot4;
			local has_slot5 = ("slot5" in currentInv) && currentInv.slot5;

			local is_all_empty = !has_slot0 && !has_slot1 && !has_slot2 && !has_slot3 && !has_slot4 && !has_slot5;

			if(is_all_empty && !has_slot1){
				player.GiveItem("weapon_pistol");
				is_slot1_ok = false;
				has_slot1 = true;
			}

			if(::rs_cp.giveWepapon_AtLeast == 2 && !has_slot0){
				local tier1_wep = ["smg", "smg_silenced", "smg_mp5", "pumpshotgun", "shotgun_chrome"];
				player.GiveItem("weapon_"+tier1_wep[RandomInt(0, tier1_wep.len()-1)]);
				is_slot0_ok = true;
			}
		}
		
		// 該当スロットがカラの場合、投擲物を渡す
		if(::rs_cp.giveThrowable > 0){
			local currentInv = {};
			GetInvTable(player, currentInv);

			local has_slot2 = ("slot2" in currentInv) && currentInv.slot2;
			local has_saved_slot2 = ("slot2" in savedData) && savedData.slot2.len() > 0;

			if(!has_saved_slot2 && !has_slot2){
				local throwable_name = null;

				switch(::rs_cp.giveThrowable){
					case 1: {
						local throwable_list = ["weapon_molotov", "weapon_pipe_bomb", "weapon_vomitjar"];
						throwable_name = throwable_list[RandomInt(0, throwable_list.len() - 1)];
						break;
					}
					case 2: throwable_name = "weapon_molotov"; break;
					case 3: throwable_name = "weapon_pipe_bomb"; break;
					case 4: throwable_name = "weapon_vomitjar"; break;
				}

				if(throwable_name != null)
					player.GiveItem(throwable_name);
			}
		}

		// 該当スロットがカラの場合、救急キットを渡す
		if(::rs_cp.giveMedkit){
			local currentInv = {};
			GetInvTable(player, currentInv);

			local has_medkit = ("slot3" in currentInv) && currentInv.slot3 && currentInv.slot3.GetClassname() == "weapon_first_aid_kit";
			if(!has_medkit)
				player.GiveItem("weapon_first_aid_kit");
		}

		// 該当スロットがカラの場合、鎮痛剤orアドレナリンを渡す
		if(::rs_cp.giveTempHealItem > 0){
			local currentInv = {};
			GetInvTable(player, currentInv);

			local has_slot4 = ("slot4" in currentInv) && currentInv.slot4;
			local has_saved_slot4 = ("slot4" in savedData) && savedData.slot4.len() > 0;

			if(!has_saved_slot4 && !has_slot4){
				local tempheal_name = null;

				switch(::rs_cp.giveTempHealItem){
					case 1: {
						local tempheal_list = ["weapon_pain_pills", "weapon_adrenaline"];
						tempheal_name = tempheal_list[RandomInt(0, tempheal_list.len() - 1)];
						break;
					}
					case 2: tempheal_name = "weapon_pain_pills"; break;
					case 3: tempheal_name = "weapon_adrenaline"; break;
				}

				if(tempheal_name != null)
					player.GiveItem(tempheal_name);
			}
		}

		local restoredInv = {};
		GetInvTable(player, restoredInv);
		
		if(is_slot0_ok && ("slot0" in restoredInv) && restoredInv.slot0)
		{
			if("clip" in savedData.slot0) //前面のAmmo
				restoredInv.slot0.SetClip1(savedData.slot0.clip);
			
			if(::rs_cp.giveAmmo == 0){
				// 倍率指定で上書きしない場合は、保存時の弾薬数を復元する
				if(("ammo" in savedData.slot0) && ("ammo_type" in savedData.slot0))
					NetProps.SetPropIntArray(player, "m_iAmmo", savedData.slot0.ammo, savedData.slot0.ammo_type);
			}
			else{
				local AmmoType = NetProps.GetPropInt(restoredInv.slot0, "m_iPrimaryAmmoType");
				local MaxAmmo = ::rs_cp.getMaxAmmo(restoredInv.slot0, AmmoType);
				local targetAmmo = floor(MaxAmmo * ::rs_cp.giveAmmo_Multiply);

				if(::rs_cp.giveAmmo == 1){
					NetProps.SetPropIntArray(player, "m_iAmmo", targetAmmo, AmmoType);
				}
				else if(::rs_cp.giveAmmo == 2){
					local currentAmmo = NetProps.GetPropIntArray(player, "m_iAmmo", AmmoType);

					if(currentAmmo < targetAmmo)
						NetProps.SetPropIntArray(player, "m_iAmmo", targetAmmo, AmmoType);
				}
			}

			if("upgrade_bits" in savedData.slot0)
				NetProps.SetPropInt(restoredInv.slot0, "m_upgradeBitVec", savedData.slot0.upgrade_bits);

			if("upg_am" in savedData.slot0)
				NetProps.SetPropInt(restoredInv.slot0, "m_nUpgradedPrimaryAmmoLoaded", savedData.slot0.upg_am);
		}

		if(is_slot1_ok && ("slot1" in restoredInv) && restoredInv.slot1)
		{
			restoredInv.slot1.SetClip1(savedData.slot1.clip);
		}
	}
	
	function getMaxAmmo(weapon, AmmoType)
	{		
		if (weapon.GetClassname().find("weapon_") == null)
			return 0;
		
		if ( AmmoType == 1 || AmmoType == 2 )
			return Convars.GetFloat( "ammo_pistol_max" ).tointeger();
		else if ( AmmoType == 3 )
			return Convars.GetFloat( "ammo_assaultrifle_max" ).tointeger();
		else if ( AmmoType == 5 )
			return Convars.GetFloat( "ammo_smg_max" ).tointeger();
		else if ( AmmoType == 6 )
			return Convars.GetFloat( "ammo_m60_max" ).tointeger();
		else if ( AmmoType == 7 )
			return Convars.GetFloat( "ammo_shotgun_max" ).tointeger();
		else if ( AmmoType == 8 )
			return Convars.GetFloat( "ammo_autoshotgun_max" ).tointeger();
		else if ( AmmoType == 9 )
			return Convars.GetFloat( "ammo_huntingrifle_max" ).tointeger();
		else if ( AmmoType == 10 )
			return Convars.GetFloat( "ammo_sniperrifle_max" ).tointeger();
		else if ( AmmoType == 17 )
			return Convars.GetFloat( "ammo_grenadelauncher_max" ).tointeger();
		else if ( AmmoType == 18 )
			return Convars.GetFloat( "ammo_adrenaline_max" ).tointeger();
		else if ( AmmoType == 19 )
			return Convars.GetFloat( "ammo_chainsaw_max" ).tointeger();
		
		return 0;
	}
	
	function OnGameEvent_finale_start(params)
	{
		::rs_cp.isFinaleStart = true;
		::rs_cp.debugPrint("Stop Save: finale_start");
	}
	function OnGameEvent_gauntlet_finale_start(params)
	{
		::rs_cp.isFinaleStart = true;
		::rs_cp.debugPrint("Stop Save: gauntlet_finale_start");
	}
	function isHordeNow()
	{
		local pending = Director.GetPendingMobCount();

		local msg = "\x05"+"CI Pending: "+pending;

		if(pending > 0){
			::rs_cp.debugPrint(msg);	
			return true;
		}

		return ::rs_cp.isCI_Rush_MoreThan_Idle(msg);
	}
	// 突撃中のCIが アイドル状態のCI より多いかどうかの判定。多ければホードの可能性大
	// MobRush = 生存者めがけて向かってきているかどうか
	function isCI_Rush_MoreThan_Idle(msg)
	{
		local ct_rush = 0; local ct_idle = 0;
		local ent = null;
		while (ent = Entities.FindByClassname(ent, "infected"))
		{
			if (ent.IsValid() && NetProps.GetPropInt(ent, "m_lifeState") == 0)
			{
				if(NetProps.GetPropInt(ent, "m_mobRush"))
					ct_rush++;
				else
					ct_idle++;
			}
		}
		
		::rs_cp.debugPrint(msg + format(", Idle: %d, Rush: %d", ct_idle, ct_rush));
		
		return (ct_rush > ct_idle);
	}
	
	function isAlarmSoundPlaying()
	{
		return ::rs_cp.isAlarmSoundActive;
	}
	function setAlarmSoundActive(active)
	{
		if(::rs_cp.isAlarmSoundActive == active)
			return;

		::rs_cp.isAlarmSoundActive = active;

		if(active)
			::rs_cp.debugPrint("\x04" + "Alarm sound started.");
		else
			::rs_cp.debugPrint("\x04" + "Alarm sound stopped.");
	}
	function isAlarmSoundTargetName(targetName, alarmNames)
	{
		if(targetName == null || targetName == "")
			return false;

		local target = targetName.tolower();

		foreach(name in alarmNames){
			if(target == name)
				return true;
		}

		return false;
	}
	function setupAlarmSoundWatcher()
	{
		local alarmSoundWatcherName = "rs_cp_alarm_watcher_" + UniqueString();

		local watcher = SpawnEntityFromTable("logic_script", {
			targetname = alarmSoundWatcherName
		});

		if(watcher == null || !watcher.IsValid()){
			::rs_cp.debugPrint("Failed to create alarm sound watcher.");
			return;
		}

		local alarmNames = [];

		// Sound Name が一致する ambient_generic を探す
		for(local ent; ent = Entities.FindByClassname(ent, "ambient_generic"); ){
			if(ent == null || !ent.IsValid())
				continue;

			local soundName = "";
			try{
				soundName = NetProps.GetPropString(ent, "m_iszSound");
			}
			catch(e){
				continue;
			}

			local lowerSound = soundName.tolower();

			if(lowerSound != "c5m2.security_alarm"
				&& lowerSound != "objects.emergency_alarm_loop"
				&& lowerSound != "playerzombie.cullwarn"
				&& lowerSound.find("perimeter_alarm.wav") == null
				&& lowerSound.find("alarm1.wav") == null
				&& lowerSound.find("klaxon1.wav") == null)
				continue;

			local entName = ent.GetName();
			if(entName == null || entName == "")
				continue;

			alarmNames.append(entName.tolower());
			//::rs_cp.debugPrint(format("Alarm ambient_generic found: %s | %s", entName, soundName));
		}

		if(alarmNames.len() <= 0){
			//::rs_cp.debugPrint("No alarm ambient_generic found.");
			return;
		}

		local outputNames = [
			"OnTrigger",
			"OnUser1",
			"OnUser2",
			"OnUser3",
			"OnUser4",
			"OnOpen",
			"OnClose",
			"OnFullyOpen",
			"OnFullyClosed",
			"OnPressed",
			"OnUnPressed",
			"OnTimeUp",
			"OnTimer",
			"OnStartTouch",
			"OnEndTouch",
			"OnBreak",
			"OnMapSpawn"
		];

		for(local src = Entities.First(); src != null; src = Entities.Next(src)){
			if(src == null || !src.IsValid())
				continue;

			foreach(outputName in outputNames){
				local count = 0;

				try{
					count = EntityOutputs.GetNumElements(src, outputName);
				}
				catch(e){
					continue;
				}

				for(local i = 0; i < count; i++){
					local out = {};

					try{
						EntityOutputs.GetOutputTable(src, outputName, out, i);
					}
					catch(e){
						continue;
					}

					local target = "";
					local input = "";
					local parameter = "";
					local delay = 0.0;

					if("target" in out)
						target = out.target;
					else if("targetname" in out)
						target = out.targetname;

					if("input" in out)
						input = out.input;
					else if("targetinput" in out)
						input = out.targetinput;

					if("parameter" in out)
						parameter = out.parameter;

					if("delay" in out)
						delay = out.delay;

					if(!::rs_cp.isAlarmSoundTargetName(target, alarmNames))
						continue;

					local lowerInput = input.tolower();
					local code = null;

					if(lowerInput == "playsound"){
						code = "::rs_cp.setAlarmSoundActive(true)";
					}
					else if(lowerInput == "stopsound"){
						code = "::rs_cp.setAlarmSoundActive(false)";
					}
					else if(lowerInput == "volume"){
						local vol = 0.0;
						try{
							vol = parameter.tofloat();
						}
						catch(e){
							vol = 0.0;
						}

						code = (vol <= 0.0)
							? "::rs_cp.setAlarmSoundActive(false)"
							: "::rs_cp.setAlarmSoundActive(true)";
					}

					if(code == null)
						continue;

					EntityOutputs.AddOutput(
						src,
						outputName,
						alarmSoundWatcherName,
						"RunScriptCode",
						code,
						delay,
						-1
					);
					
					/*
					::rs_cp.debugPrint(format(
						"Alarm watcher added: %s.%s -> %s %s %s",
						src.GetClassname(),
						outputName,
						target,
						input,
						parameter
					));
					*/
				}
			}
		}
	}
	
	function Effect_FadeScreen(player, red = 0, green = 0, blue = 0, alpha = 255, _duration = 5.0, _holdtime = 5.0, modulate = false, fadeFrom = false)
	{
		local flags = 4;
		if (modulate)
			flags = flags | 2;
		if (fadeFrom)
			flags = flags | 1;
		
		local spawn =
		{
			classname = "env_fade",
			duration = _duration,
			holdtime = _holdtime,
			renderamt = 255,
			rendercolor = red + " " + green + " " + blue,
			spawnflags = flags,
			targetname = "fade_screen" + UniqueString(),
		};
		
		local env_fade = g_ModeScript.CreateSingleSimpleEntityFromTable(spawn);
		DoEntFire("!self", "Alpha", alpha.tostring(), 0.0, null, env_fade);
		DoEntFire("!self", "Fade", "", 0.0, player, env_fade);
		DoEntFire("!self", "Kill", "", _duration + _holdtime, null, env_fade);
		
		return env_fade;
	}
	
	function IsSurvivorInCheckpoint(survivor)
	{
		local area = survivor.GetLastKnownArea();
		return (area && area.IsValid() && area.HasSpawnAttributes(2048));
	}
	
	function emitAmbientSoundOnAll(soundname, volume = 1.0, soundlevel = 350, pitch = 100)
	{
		local playerEnt = null
		while(playerEnt = Entities.FindByClassname(playerEnt, "player"))
		{
			EmitAmbientSoundOn(soundname, volume, pitch, soundlevel, playerEnt);
		}
	}
	
	function isOfficialMap()
	{
		local prefix_list = [
			"c1m", "c2m", "c3m", "c4m", "c5m", "c6m", "c7m",
			"c8m", "c9m", "c10m", "c11m", "c12m", "c13m", "c14m"
		];

		foreach(prefix in prefix_list){
			if(::rs_cp.s_MapName.find(prefix) != null)
				return true;
		}

		return false;
	}
	
	function normalizeSteamIDText(text)
	{
		if(text == null)
			return "";

		local result = ::rs_cp.trimSettingText(text.tostring());
		if(result.len() <= 0)
			return "";

		return result.tolower();
	}
	function loadAdminSteamID()
	{
		::rs_cp.adminSteamID = "";
		::rs_cp.adminEntIndex = -1;

		local text = FileToString(::rs_cp.dir_admin);

		// ファイルが無ければ新規作成する
		if(text == null){
			local steamid = "";
			for(local player; player = Entities.FindByClassname(player, "player"); ){
				if(player == null || !player.IsValid() || IsPlayerABot(player))
					continue;
				
				steamid = player.GetNetworkIDString() + "\r";
				break;
			}
			
			StringToFile(::rs_cp.dir_admin,
				"// Restore Checkpoint System admin SteamID file\n"
				+ "// Dedicated server only:\n"
				+ "// Write the host/admin SteamID on the first valid line.\n"
				+ "// Only the first non-empty, non-comment line is used.\n"
				+ "// Example: STEAM_1:0:12345678\n"
				+ steamid
			);
			text = FileToString(::rs_cp.dir_admin);
		}

		if(text == null)
			return;

		local lines = split(text, "\n");

		foreach(raw_line in lines){
			local line = ::rs_cp.trimSettingText(raw_line);

			if(line.len() <= 0)
				continue;

			// コメント行は無視
			if(line.len() >= 2 && line[0].tochar() == "/" && line[1].tochar() == "/")
				continue;

			// 行末コメント対応
			local comment_pos = line.find("//");
			if(comment_pos != null)
				line = ::rs_cp.trimSettingText(line.slice(0, comment_pos));

			if(line.len() <= 0)
				continue;

			// 複数SteamIDがあっても、最初の1つだけ使う
			::rs_cp.adminSteamID = ::rs_cp.normalizeSteamIDText(line);
			return;
		}
	}
	function getAdminBySteamID()
	{
		if(::rs_cp.adminSteamID == "")
			return null;

		// 以前見つけたadminを軽く確認する
		if(::rs_cp.adminEntIndex > 0){
			local cached = EntIndexToHScript(::rs_cp.adminEntIndex);

			if(cached != null && cached.IsValid() && !IsPlayerABot(cached)){
				local cached_id = ::rs_cp.normalizeSteamIDText(::rs_cp.getSurvivorNetworkID(cached));

				if(cached_id == ::rs_cp.adminSteamID)
					return cached;
			}

			::rs_cp.adminEntIndex = -1;
		}

		// dedicated server用。
		// 必要なときだけ player を走査し、見つけたら EntIndex をキャッシュする。
		for(local player; player = Entities.FindByClassname(player, "player"); ){
			if(player == null || !player.IsValid() || IsPlayerABot(player))
				continue;

			local id = ::rs_cp.normalizeSteamIDText(::rs_cp.getSurvivorNetworkID(player));

			if(id == ::rs_cp.adminSteamID){
				::rs_cp.adminEntIndex = player.GetEntityIndex();
				return player;
			}
		}

		return null;
	}
	function getAdmin()
	{
		local host = GetListenServerHost(); // ローカルサーバーはこれで拾える
		if(host != null && host.IsValid() && !IsPlayerABot(host))
			return host;

		// dedicated serverでは GetListenServerHost() が取れないため、 admin_steam_id.txt の最初のSteamIDで照会する
		return ::rs_cp.getAdminBySteamID();
	}
	
	function debugPrint(msg){
		if(::rs_cp.debug){
			local host = ::rs_cp.getAdmin();
			if(host != null){
				local tbl = {};
				LocalTime( tbl );
				local hms = tbl.hour + ":" + tbl.minute + ":" + tbl.second;
				ClientPrint(host, 3, format("\x01[debug][%s] %s", hms, msg));
			}
		}
	}
	function switch_key_setting(key)
	{
		local vars = FileToString(::rs_cp.dir_setting);
		if(vars == null)
			return;

		local pos = vars.find(key);
		if(pos == null)
			return;

		local line_end = vars.find("\n", pos);
		if(line_end == null)
			line_end = vars.len();

		local old_line = vars.slice(pos, line_end);
		local eq_pos = old_line.find("=");
		if(eq_pos == null)
			return;
		
		local flag = (key == "debug") ? ::rs_cp.debug : ::rs_cp.exportLocalFile;

		local new_line = old_line.slice(0, eq_pos + 1) + " " + (flag ? "true" : "false");

		local new_text = vars.slice(0, pos) + new_line + vars.slice(line_end);
		StringToFile(::rs_cp.dir_setting, new_text);
	}
	
	function save_ems_settings()
	{
		local vars = FileToString(dir_setting);
		local version_mismatch = (vars != null && vars.find(format("version: %s", version)) == null);

		if(vars == null || version_mismatch)
		{
			if(version_mismatch)
				::rs_cp.isVersionDifferent = true;

			StringToFile(dir_setting,
				format("// <RSCP> version: %s", version) + "\n"
				+ "// Enter only the values included in [] below." + "\n\n"

				+ "// [0.1 ~ 60.0]" + "\n"
				+ "// Interval of the timer that performs data save processing." + "\n"
				+ "// A smaller value reduces save misses, but may increase load depending on the environment." + "\n"
				+ format("thinkInterval = %.1f", ::rs_cp.thinkInterval) + "\n\n"

				+ "// [1 ~ 99]" + "\n"
				+ "// Interval of map progress used for load points." + "\n"
				+ "// If set to 20, the load point is updated each time Flow advances by 20% or more." + "\n"
				+ "// The latest updated load point is always used for restoration." + "\n"
				+ "loadIntervalFlow = " + ::rs_cp.loadIntervalFlow + "\n\n"

				+ "// [1 ~ 20]" + "\n"
				+ "// Interval of Flow used to store stock data." + "\n"
				+ "// Smaller values save more frequently, but increase the amount of data." + "\n"
				+ "stockFlow = " + ::rs_cp.stockFlow + "\n\n"

				+ "// [-1 | 1 ~ 50]" + "\n"
				+ "// Only add-on maps. If the team is wiped during a horde, restore from a stock point at least this much Flow behind the current position." + "\n"
				+ "// Because horde detection cannot be returned immediately, a save may still occur during a panic event." + "\n"
				+ "// In that case, restoring after a gate has opened and similar situations may cause the run to get stuck." + "\n"
				+ "// -1 disables this." + "\n"
				+ "hordeBehindFlow = " + ::rs_cp.hordeBehindFlow + "\n\n"

				+ "// [0.1 ~ 60.0]" + "\n"
				+ "// Number of seconds to keep panic-event detection active after the zombie rush is judged to have calmed down." + "\n"
				+ "// Even during an actual panic event, zombie activity can temporarily settle." + "\n"
				+ "// If the detection is cleared too quickly, saving may occur during the panic event." + "\n"
				+ format("disablePanicDelay = %.1f", ::rs_cp.disablePanicDelay) + "\n\n"

				+ "// [true | false]" + "\n"
				+ "// If true, incapacitated survivors are excluded from save candidates." + "\n"
				+ "exclude_IncapSurv = " + ::rs_cp.exclude_IncapSurv + "\n\n"

				+ "// [true | false]" + "\n"
				+ "// If true, survivors pinned by Special Infected are excluded from save candidates." + "\n"
				+ "exclude_DominatedSurv = " + ::rs_cp.exclude_DominatedSurv + "\n\n"

				+ "// [true | false]" + "\n"
				+ "// If true, saving is disabled while fighting a Tank." + "\n"
				+ "noSave_DuringTankInPlay = " + ::rs_cp.noSave_DuringTankInPlay + "\n\n"

				+ "// [-1 | 50 ~ 100]" + "\n"
				+ "// Do not save after the specified Flow." + "\n"
				+ "// This stops the save-processing timer." + "\n"
				+ "noSave_AfterFlow = " + ::rs_cp.noSave_AfterFlow + "\n\n"

				+ "// [1 | 2]" + "\n"
				+ "// Timing for performing restoration." + "\n"
				+ "// 1 = immediately at round start, 2 = after leaving the saferoom." + "\n"
				+ "// On some add-on maps, leaving-the-saferoom may be detected even while still inside the saferoom." + "\n"
				+ "restoreTiming = " + ::rs_cp.restoreTiming + "\n\n"

				+ "// [0 ~ 2]" + "\n"
				+ "// Whether to notify all when a checkpoint is saved." + "\n"
				+ "// 0 = disabled, 1 = print only, 2 = print and sound." + "\n"
				+ "announce_Save = " + ::rs_cp.announce_Save + "\n\n"

				+ "// [\"string\"]" + "\n"
				+ "// Sound script used for the save notifications when announce_Save is 2." + "\n"
				+ "announce_Save_SndName = \"" + ::rs_cp.announce_Save_SndName + "\"" + "\n\n"
				
				+ "// [true | false]" + "\n"
				+ "// If true, notify all before restoring." + "\n"
				+ "announce_Restore = " + ::rs_cp.announce_Restore + "\n\n"

				+ "// [-1 | 1 ~ 1800]" + "\n"
				+ "// After restoration succeeds, prevent zombies from spawning behind the team for the specified number of seconds while fighting a Tank." + "\n"
				+ "// This is meant to prevent the retreat route from being blocked by CI spawning behind the team." + "\n"
				+ "// -1 disables this." + "\n"
				+ "prohibitBehindTime = " + ::rs_cp.prohibitBehindTime + "\n\n"

				+ "// [true | false]" + "\n"
				+ "// If true, fade to black during restoration." + "\n"
				+ "// This may not work if the map itself already performs a fade-out." + "\n"
				+ "restore_FadeOut = " + ::rs_cp.restore_FadeOut + "\n\n"

				+ "// [\"string\"]" + "\n"
				+ "// Sound script used during restoration." + "\n"
				+ "// If left blank, no sound is played." + "\n"
				+ "restore_SndName = \"" + ::rs_cp.restore_SndName + "\"" + "\n\n"

				+ "// [0 ~ 2]" + "\n"
				+ "// Minimum weapon to give after restoration succeeds." + "\n"
				+ "// 0 = give nothing (not recommended), 1 = pistol only, 2 = pistol and a Tier 1 weapon." + "\n"
				+ "giveWepapon_AtLeast = " + ::rs_cp.giveWepapon_AtLeast + "\n\n"

				+ "// [0 ~ 2]" + "\n"
				+ "// Whether to set primary-weapon ammo to the multiplier specified by giveAmmo_Multiply after restoration succeeds." + "\n"
				+ "// 0 = do not set by multiplier, 1 = always set, 2 = set only if current ammo is below the target amount." + "\n"
				+ "giveAmmo = " + ::rs_cp.giveAmmo + "\n\n"

				+ "// [0.0 ~ 1.0]" + "\n"
				+ "// Ammo multiplier used when giveAmmo is 1 or higher." + "\n"
				+ format("giveAmmo_Multiply = %.1f", ::rs_cp.giveAmmo_Multiply) + "\n\n"

				+ "// [0 ~ 4]" + "\n"
				+ "// Item to give if the throwable slot is empty after restoration succeeds." + "\n"
				+ "// 0 = give nothing, 1 = random, 2 = Molotov, 3 = Pipe bomb, 4 = Vomitjar." + "\n"
				+ "giveThrowable = " + ::rs_cp.giveThrowable + "\n\n"

				+ "// [true | false]" + "\n"
				+ "// If true, give a first aid kit if the medical slot does not contain one after restoration succeeds." + "\n"
				+ "giveMedkit = " + ::rs_cp.giveMedkit + "\n\n"

				+ "// [0 ~ 3]" + "\n"
				+ "// Item to give if the temporary healing item slot is empty after restoration succeeds." + "\n"
				+ "// 0 = give nothing, 1 = random, 2 = Pain pills, 3 = Adrenaline." + "\n"
				+ "giveTempHealItem = " + ::rs_cp.giveTempHealItem + "\n\n"
				
				+ "// [true | false]" + "\n"
				+ "// If true, restore HP." + "\n"
				+ "// If false, keep the HP from immediately after round start." + "\n"
				+ "restoreHP = " + ::rs_cp.restoreHP + "\n\n"

				+ "// [-1 | 2 ~ 100]" + "\n"
				+ "// If HP is below the specified value when restored, set HP to that value." + "\n"
				+ "// -1 disables this." + "\n"
				+ "restoreHP_AtLeast = " + ::rs_cp.restoreHP_AtLeast + "\n\n"

				+ "// [0 ~ 3]" + "\n"
				+ "// HP adjustment pattern used when restoreHP_AtLeast is 2 or higher." + "\n"
				+ "// 0 = compensate with real HP." + "\n"
				+ "// 1 = compensate with temporary HP." + "\n"
				+ "// 2 = if real HP is insufficient, add real HP and keep temporary HP as is." + "\n"
				+ "// 3 = if real HP is insufficient, add real HP and keep only the temporary HP that remains after reaching the target value." + "\n"
				+ "restoreHP_Type = " + ::rs_cp.restoreHP_Type + "\n\n"

				+ "// [true | false]" + "\n"
				+ "// If true, restoration is disabled by default (however, the save-processing timer continues to run)." + "\n"
				+ "// It can be enabled with !rscp on, and !rscp command takes precedence." + "\n"
				+ "initiallyDisabled = " + ::rs_cp.initiallyDisabled + "\n\n"
				
				+ "// [true | false]" + "\n"
				+ "// If true, also save stock data and restore checkpoint data to a local file." + "\n"
				+ "// This allows restoration even after restarting the game." + "\n"
				+ "exportLocalFile = " + ::rs_cp.exportLocalFile + "\n\n"
				
				+ "// [true | false]" + "\n"
				+ "// If true, notify only the server host about internal processing details." + "\n"
				+ "debug = " + ::rs_cp.debug + "\n"
			);
		}
	}
	
	function load_ems_settings()
	{
		local vars = FileToString(dir_setting);
		if(vars == null)
			return;

		::rs_cp.settingsLoadWarnings = [];

		local parsed = {};
		local lines = split(vars, "\n");

		foreach(raw_line in lines){
			local line = ::rs_cp.trimSettingText(raw_line);
			if(line.len() <= 0)
				continue;

			// コメント行は無視
			if(line.len() >= 2 && line[0].tochar() == "/" && line[1].tochar() == "/")
				continue;

			local pair = split(line, "=");
			if(pair.len() < 2)
				continue;

			local key = ::rs_cp.trimSettingText(pair[0]);

			local value_text = "";
			for(local i = 1; i < pair.len(); i++){
				if(i > 1)
					value_text += "=";
				value_text += pair[i];
			}
			value_text = ::rs_cp.trimSettingText(value_text);

			if(key.len() <= 0)
				continue;

			parsed[key] <- ::rs_cp.parseSettingValue(value_text);
		}

		foreach(key in ::rs_cp.setting_keys){
			if(!(key in parsed)){
				::rs_cp.settingsLoadWarnings.append(
					format("Missing setting '\x04%s\x01' in rscp_settings.txt.", key)
				);
				continue;
			}

			::rs_cp.applyLoadedSettingValue(key, parsed[key]);
		}
	}
	function printLoadedSettingsToConsole()
	{
		local function settingValueToConsoleText(value){
			local value_type = typeof value;
	
			if(value_type == "string")
				return "\"" + value + "\"";
	
			if(value_type == "bool")
				return value ? "true" : "false";
	
			return value.tostring();	
		}
		
		foreach(key in ::rs_cp.setting_keys){
			if(!(key in ::rs_cp))
				continue;

			printl(format(
				"[RSCP][Settings] %s = %s",
				key,
				settingValueToConsoleText(::rs_cp[key])
			));
		}
	}
	function trimSettingText(text)
	{
		local start = 0;
		local last = text.len() - 1;

		while(start <= last){
			local ch = text[start].tochar();
			if(ch == " " || ch == "\t" || ch == "\r" || ch == "\n")
				start++;
			else
				break;
		}

		while(last >= start){
			local ch = text[last].tochar();
			if(ch == " " || ch == "\t" || ch == "\r" || ch == "\n")
				last--;
			else
				break;
		}

		local result = "";
		for(local i = start; i <= last; i++)
			result += text[i].tochar();

		return result;
	}
	function parseSettingValue(text)
	{
		local trimmed = ::rs_cp.trimSettingText(text);
		if(trimmed.len() <= 0)
			return "";

		// "string"
		if(trimmed.len() >= 2 && trimmed[0].tochar() == "\"" && trimmed[trimmed.len()-1].tochar() == "\""){
			local inner = "";
			for(local i = 1; i < trimmed.len()-1; i++)
				inner += trimmed[i].tochar();
			return inner;
		}

		// bool
		local lower = trimmed.tolower();
		if(lower == "true")
			return true;
		if(lower == "false")
			return false;

		// int / float
		local has_dot = false;
		local digit_count = 0;
		for(local i = 0; i < trimmed.len(); i++){
			local ch = trimmed[i].tochar();

			if(i == 0 && (ch == "-" || ch == "+"))
				continue;

			if(ch == "."){
				if(has_dot)
					return trimmed;
				has_dot = true;
				continue;
			}

			if(ch >= "0" && ch <= "9"){
				digit_count++;
				continue;
			}

			return trimmed;
		}

		if(digit_count <= 0)
			return trimmed;

		return has_dot ? trimmed.tofloat() : trimmed.tointeger();
	}
	function applyLoadedSettingValue(key, value)
	{
		if(!(key in ::rs_cp))
			return;

		local default_value = ::rs_cp[key];
		local typeA = typeof default_value;
		local typeB = typeof value;

		if(typeA == typeB){
			::rs_cp[key] = value;
			return;
		}

		// int <-> float
		if(typeA == "integer" && typeB == "float"){
			::rs_cp[key] = value.tointeger();
			return;
		}
		if(typeA == "float" && typeB == "integer"){
			::rs_cp[key] = value.tofloat();
			return;
		}

		::rs_cp.settingsLoadWarnings.append(
			format("Invalid type or value for setting '\x04%s\x01' in rscp_settings.txt. Expected %s, got %s.", key, typeA, typeB)
		);
	}
	
	/*
	*	GetScriptScope()やinstance自体を保存すると、ゲームを切断したときやbotと人間が切り替わった時にリセットされてしまう。
	*	そのため、「同じ生存者」を再特定するための自前IDを用意し、
	*		RestoreTable() で保存済みデータを読む → 今いる全生存者を列挙する → その中から 保存していた自前IDが一致する entity を探す
	*
	*	今いるプレイヤーの最大UIDを見てから採番する
	*/
	function getCurrentMaxSurvivorUID()
	{
		local max_uid = 0;
		for(local ent; ent = Entities.FindByClassname(ent, "player"); ){
			if(ent == null || !ent.IsValid() || ent.GetZombieType() != 9)
				continue;

			ent.ValidateScriptScope();
			local scope = ent.GetScriptScope();

			if(("SurvivorUID" in scope) && scope.SurvivorUID > max_uid)
				max_uid = scope.SurvivorUID;
		}

		return max_uid;
	}
	function EnsureSurvivorUID(ent)
	{
		if(ent == null || !ent.IsValid())
			return null;
	
		ent.ValidateScriptScope();
		local scope = ent.GetScriptScope();
	
		if(!("SurvivorUID" in scope)){
			local max_uid = ::rs_cp.getCurrentMaxSurvivorUID();
	
			scope.SurvivorUID <- max_uid + 1;
		}
	
		return scope.SurvivorUID;
	}
	function FindSurvivorByUID(uid)
	{
		local ent = null;
		while (ent = Entities.FindByClassname(ent, "player"))
		{
			if (ent == null || !ent.IsValid())
				continue;
	
			local scope = ent.GetScriptScope();
			if (!("SurvivorUID" in scope))
				continue;
	
			if (scope.SurvivorUID == uid)
				return ent;
		}
	
		return null;
	}
	function getSurvivorCharacter(surv)
	{
		if(surv == null || !surv.IsValid())
			return -1;

		try{
			return NetProps.GetPropInt(surv, "m_survivorCharacter");
		}
		catch(e){}

		return -1;
	}
	function getSurvivorNetworkID(player)
	{
		if(player == null || !player.IsValid())
			return "";

		if(IsPlayerABot(player))
			return "";

		local id = "";

		try{
			id = player.GetNetworkIDString();
		}
		catch(e){
			id = "";
		}

		if(id == null)
			return "";

		id = id.tostring();

		if(id == "" || id.tolower() == "bot")
			return "";

		return id;
	}

	function isTemporaryL4LSurvivorClient(surv)
	{
		if(surv == null || !surv.IsValid())
			return false;

		// 通常Botは除外しない
		if(IsPlayerABot(surv))
			return false;

		// 本物の人間プレイヤーなら NetworkID が取れる想定
		local networkid = ::rs_cp.getSurvivorNetworkID(surv);
		if(networkid != "")
			return false;

		local name = surv.GetPlayerName();
		if(name == null)
			return false;

		name = name.tolower();

		// L4L が一時的に作る fake client 対策
		if(name.find("survivorbot") != null)
			return true;

		return false;
	}
	function isRestoreRowUsed(index)
	{
		local key = index.tostring();
		return ((key in ::rs_cp.restoreUsedRowIndexes) && ::rs_cp.restoreUsedRowIndexes[key]);
	}
	function markRestoreRowUsed(index)
	{
		::rs_cp.restoreUsedRowIndexes[index.tostring()] <- true;
	}
	function findRestoreRowForSurvivor(surv, scopeUID)
	{
		if(::rs_cp.restoreDataSurv == null || !("list" in ::rs_cp.restoreDataSurv))
			return null;

		local list = ::rs_cp.restoreDataSurv.list;

		// 1. 通常ラウンド継続時: UID一致を最優先
		foreach(i, row in list){
			if(::rs_cp.isRestoreRowUsed(i))
				continue;

			if(("uid" in row) && row.uid == scopeUID){
				::rs_cp.markRestoreRowUsed(i);
				return row;
			}
		}
		
		// exportLocalFile=false の場合は、従来通り UID 一致のみで復元する
		if(!::rs_cp.exportLocalFile)
			return null;

		// 2. ゲーム再起動後の人間プレイヤー: NetworkIDで照合
		local networkid = ::rs_cp.getSurvivorNetworkID(surv);
		if(networkid != ""){
			foreach(i, row in list){
				if(::rs_cp.isRestoreRowUsed(i))
					continue;

				if(("networkid" in row) && row.networkid == networkid){
					::rs_cp.markRestoreRowUsed(i);
					return row;
				}
			}
		}

		// 3. キャラクターが保存側・現在側どちらも一意なら character で照合
		// 同じキャラクターが重複している場合は誤割当を避けるため、ここでは使わない
		local character = ::rs_cp.getSurvivorCharacter(surv);
		local savedCharacterCount = 0;
		local currentCharacterCount = 0;
		local candidateKey = "";
		local candidateRow = null;

		foreach(i, row in list){
			if(::rs_cp.isRestoreRowUsed(i))
				continue;

			if(("character" in row) && row.character == character){
				savedCharacterCount++;
				candidateKey = i;
				candidateRow = row;
			}
		}

		for(local ent; ent = Entities.FindByClassname(ent, "player"); ){
			if(ent == null || !ent.IsValid() || ent.GetZombieType() != 9)
				continue;

			if(::rs_cp.getSurvivorCharacter(ent) == character)
				currentCharacterCount++;
		}

		if(savedCharacterCount == 1 && currentCharacterCount == 1 && candidateRow != null){
			::rs_cp.markRestoreRowUsed(candidateKey);
			return candidateRow;
		}

		// 4. 最後の保険:
		// 未使用のrowを1人1個ずつ割り当てる。
		// 同キャラ重複時でも、同じrowを複数人に使わない。
		foreach(i, row in list){
			if(::rs_cp.isRestoreRowUsed(i))
				continue;

			::rs_cp.markRestoreRowUsed(i);
			return row;
		}

		return null;
	}
	function transferUID(oldEnt, newEnt)
	{
		if (oldEnt == null || newEnt == null) return;
		if (!oldEnt.IsValid() || !newEnt.IsValid()) return;
		
		local oldScope = oldEnt.GetScriptScope();
		
		if ("SurvivorUID" in oldScope)
		{
			newEnt.ValidateScriptScope();
			local newScope = newEnt.GetScriptScope();
			newScope.SurvivorUID <- oldScope.SurvivorUID;
		}
		else
		{
			::rs_cp.EnsureSurvivorUID(newEnt);
		}
	}
	OnGameEvent_player_bot_replace = function(params) {
		local player = GetPlayerFromUserID(params.player);
		local bot = GetPlayerFromUserID(params.bot);
		::rs_cp.transferUID(player, bot);
	}
	
	OnGameEvent_bot_player_replace = function(params) {
		local bot = GetPlayerFromUserID(params.bot);
		local player = GetPlayerFromUserID(params.player);
		::rs_cp.transferUID(bot, player);
	}
}

IncludeScript("restore_checkpoint/local_export");

__CollectEventCallbacks(::rs_cp, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);