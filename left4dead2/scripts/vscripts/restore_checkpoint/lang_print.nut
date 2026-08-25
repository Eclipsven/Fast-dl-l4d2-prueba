::rs_cp_print<-{
	function printLang(t = "", tbl = {})
	{
		if(t == "warning_stop_restore")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "[ToAdmin] " + "Restore is disabled for this chapter.",
				"\x04" + "[ToAdmin] " + "このチャプターでの復元が無効になっています。",
				"\x04" + "[ToAdmin] " + "이 챕터에서는 복원이 비활성화되어 있습니다.",
				"\x04" + "[ToAdmin] " + "本章节的恢复已被禁用。",
				"\x04" + "[ToAdmin] " + "此章節的復原已被停用。",
				"\x04" + "[ToAdmin] " + "Khôi phục đã bị tắt trong chương này.",
				"\x04" + "[ToAdmin] " + "การกู้คืนถูกปิดใช้งานสำหรับด่านนี้",
				"\x04" + "[ToAdmin] " + "Восстановление отключено для этой главы.",
				"\x04" + "[ToAdmin] " + "La restauración está desactivada en este capítulo.",
				"\x04" + "[ToAdmin] " + "La restauration est désactivée pour ce chapitre.",
				"\x04" + "[ToAdmin] " + "Die Wiederherstellung ist für dieses Kapitel deaktiviert."
			);
		else if(t == "failed_restore")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + format("%s failed to restore.", tbl.playerName),
				"\x04" + format("%s は復元に失敗しました。", tbl.playerName),
				"\x04" + format("%s 복원에 실패했습니다.", tbl.playerName),
				"\x04" + format("%s 恢复失败。", tbl.playerName),
				"\x04" + format("%s 復原失敗。", tbl.playerName),
				"\x04" + format("%s khôi phục thất bại.", tbl.playerName),
				"\x04" + format("%s กู้คืนไม่สำเร็จ", tbl.playerName),
				"\x04" + format("%s: восстановление не удалось.", tbl.playerName),
				"\x04" + format("%s no pudo restaurarse.", tbl.playerName),
				"\x04" + format("Échec de la restauration pour %s.", tbl.playerName),
				"\x04" + format("Die Wiederherstellung von %s ist fehlgeschlagen.", tbl.playerName)
			);
		else if(t == "restart_checkpoint")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "Restarting from the last checkpoint.",
				"\x04" + "最終チェックポイントから再開します。",
				"\x04" + "마지막 체크포인트에서 다시 시작합니다.",
				"\x04" + "将从上一个检查点重新开始。",
				"\x04" + "將從上一個檢查點重新開始。",
				"\x04" + "Sẽ tiếp tục từ điểm kiểm tra cuối cùng.",
				"\x04" + "จะเริ่มใหม่จากจุดตรวจล่าสุด",
				"\x04" + "Возобновление с последней контрольной точки.",
				"\x04" + "Reanudando desde el último punto de control.",
				"\x04" + "Reprise depuis le dernier point de contrôle.",
				"\x04" + "Neustart ab dem letzten Kontrollpunkt."
			);
		else if(t == "disabled_notice")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "[ToAdmin] " + "Restore is disabled. Even if the team is wiped, restoration will not occur.",
				"\x04" + "[ToAdmin] " + "復元が無効です。次全滅しても復元されません。",
				"\x04" + "[ToAdmin] " + "복원이 비활성화되어 있습니다. 다음에 전멸해도 복원되지 않습니다.",
				"\x04" + "[ToAdmin] " + "恢复已禁用。即使下次团灭也不会恢复。",
				"\x04" + "[ToAdmin] " + "復原已停用。即使下次團滅也不會復原。",
				"\x04" + "[ToAdmin] " + "Khôi phục đang bị tắt. Dù cả đội bị quét sạch lần nữa cũng sẽ không được khôi phục.",
				"\x04" + "[ToAdmin] " + "การกู้คืนถูกปิดใช้งานอยู่ ต่อให้ทีมตายหมดอีกครั้งก็จะไม่กู้คืน",
				"\x04" + "[ToAdmin] " + "Восстановление отключено. Даже при следующем полном вайпе восстановление не произойдёт.",
				"\x04" + "[ToAdmin] " + "La restauración está desactivada. Aunque el equipo sea aniquilado de nuevo, no se restaurará.",
				"\x04" + "[ToAdmin] " + "La restauration est désactivée. Même en cas d'anéantissement total, elle ne sera pas effectuée.",
				"\x04" + "[ToAdmin] " + "Die Wiederherstellung ist deaktiviert. Selbst bei einem weiteren Teamwipe wird nicht wiederhergestellt."
			);
		else if(t == "checkpoint_saved")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "Checkpoint saved!",
				"\x04" + "チェックポイントがセーブされました！",
				"\x04" + "체크포인트가 저장되었습니다!",
				"\x04" + "检查点已保存！",
				"\x04" + "檢查點已儲存！",
				"\x04" + "Điểm kiểm tra đã được lưu!",
				"\x04" + "บันทึกจุดตรวจแล้ว!",
				"\x04" + "Контрольная точка сохранена!",
				"\x04" + "¡Punto de control guardado!",
				"\x04" + "Point de contrôle sauvegardé !",
				"\x04" + "Kontrollpunkt gespeichert!"
			);
		else if(t == "local_file_restore_start")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "Local save data was found, so restoration will start.",
				"\x04" + "ローカルファイルにデータが存在するため、復元を開始します。",
				"\x04" + "로컬 파일에 데이터가 있어 복원을 시작합니다.",
				"\x04" + "检测到本地文件中存在数据，开始恢复。",
				"\x04" + "偵測到本機檔案中有資料，開始復原。",
				"\x04" + "Đã tìm thấy dữ liệu trong tệp cục bộ, bắt đầu khôi phục.",
				"\x04" + "พบข้อมูลในไฟล์ภายในเครื่อง จึงจะเริ่มการกู้คืน",
				"\x04" + "В локальном файле найдены данные, начинается восстановление.",
				"\x04" + "Se encontraron datos en el archivo local, iniciando la restauración.",
				"\x04" + "Des données ont été trouvées dans le fichier local, la restauration va commencer.",
				"\x04" + "Lokale Speicherdaten wurden gefunden, die Wiederherstellung wird gestartet."
			);
		/*
		else if(t == "checkpoint_saved")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + format("Checkpoint saved! (Position: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("チェックポイントがセーブされました！ (Position: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("체크포인트가 저장되었습니다! (위치: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("检查点已保存！ (位置: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("檢查點已儲存！ (位置: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("Điểm kiểm tra đã được lưu! (Vị trí: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("บันทึกจุดตรวจแล้ว! (ตำแหน่ง: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("Контрольная точка сохранена! (Позиция: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("¡Punto de control guardado! (Posición: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("Point de contrôle sauvegardé ! (Position : %s) (%.1f%%)", tbl.playerName, tbl.stand_flow),
				"\x04" + format("Kontrollpunkt gespeichert! (Position: %s) (%.1f%%)", tbl.playerName, tbl.stand_flow)
			);
		*/
		else if(t == "restore_off")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "[ToAdmin] " + "Restore OFF: Restoration has been disabled for this chapter.",
				"\x04" + "[ToAdmin] " + "Restore OFF: このチャプターでの復元を無効化しました。",
				"\x04" + "[ToAdmin] " + "Restore OFF: 이 챕터에서 복원을 비활성화했습니다.",
				"\x04" + "[ToAdmin] " + "Restore OFF: 已禁用本章节的恢复。",
				"\x04" + "[ToAdmin] " + "Restore OFF: 已停用此章節的復原。",
				"\x04" + "[ToAdmin] " + "Restore OFF: Đã tắt khôi phục cho chương này.",
				"\x04" + "[ToAdmin] " + "Restore OFF: ปิดการกู้คืนสำหรับด่านนี้แล้ว",
				"\x04" + "[ToAdmin] " + "Restore OFF: Восстановление для этой главы отключено.",
				"\x04" + "[ToAdmin] " + "Restore OFF: La restauración ha sido desactivada para este capítulo.",
				"\x04" + "[ToAdmin] " + "Restore OFF: La restauration a été désactivée pour ce chapitre.",
				"\x04" + "[ToAdmin] " + "Restore OFF: Die Wiederherstellung wurde für dieses Kapitel deaktiviert."
			);
		else if(t == "restore_on")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "[ToAdmin] " + "Restore ON: Restoration has been enabled for this chapter.",
				"\x04" + "[ToAdmin] " + "Restore ON: このチャプターでの復元を有効化しました。",
				"\x04" + "[ToAdmin] " + "Restore ON: 이 챕터에서 복원을 활성화했습니다.",
				"\x04" + "[ToAdmin] " + "Restore ON: 已启用本章节的恢复。",
				"\x04" + "[ToAdmin] " + "Restore ON: 已啟用此章節的復原。",
				"\x04" + "[ToAdmin] " + "Restore ON: Đã bật khôi phục cho chương này.",
				"\x04" + "[ToAdmin] " + "Restore ON: เปิดการกู้คืนสำหรับด่านนี้แล้ว",
				"\x04" + "[ToAdmin] " + "Restore ON: Восстановление для этой главы включено.",
				"\x04" + "[ToAdmin] " + "Restore ON: La restauración ha sido activada para este capítulo.",
				"\x04" + "[ToAdmin] " + "Restore ON: La restauration a été activée pour ce chapitre.",
				"\x04" + "[ToAdmin] " + "Restore ON: Die Wiederherstellung wurde für dieses Kapitel aktiviert."
			);
		else if(t == "settings_reset_notice")
			::rs_cp_print.ClientPrint_11Language(
				null,
				"\x04" + "[ToAdmin] " + "Due to an update, rscp_settings.txt has been reset. Please check it.",
				"\x04" + "[ToAdmin] " + "アップデートにより rscp_settings.txt がリセットされています。確認してください。",
				"\x04" + "[ToAdmin] " + "업데이트로 인해 rscp_settings.txt가 초기화되었습니다. 확인해 주세요.",
				"\x04" + "[ToAdmin] " + "由于更新，rscp_settings.txt 已被重置。请检查。",
				"\x04" + "[ToAdmin] " + "由於更新，rscp_settings.txt 已被重設。請確認。",
				"\x04" + "[ToAdmin] " + "Do bản cập nhật, rscp_settings.txt đã được đặt lại. Vui lòng kiểm tra.",
				"\x04" + "[ToAdmin] " + "เนื่องจากการอัปเดต rscp_settings.txt ถูกรีเซ็ตแล้ว โปรดตรวจสอบ",
				"\x04" + "[ToAdmin] " + "Из-за обновления rscp_settings.txt был сброшен. Пожалуйста, проверьте его.",
				"\x04" + "[ToAdmin] " + "Debido a una actualización, rscp_settings.txt se ha restablecido. Por favor, revísalo.",
				"\x04" + "[ToAdmin] " + "Suite à une mise à jour, rscp_settings.txt a été réinitialisé. Veuillez le vérifier.",
				"\x04" + "[ToAdmin] " + "Durch ein Update wurde rscp_settings.txt zurückgesetzt. Bitte überprüfe die Datei."
			);
	}
	
	function ClientPrint_11Language(player = null, eng_msg = "", jpn_msg = "", kr_msg = "", sch_msg = "", tch_msg = "",
		viet_msg = "", thai_msg = "", rus_msg = "", spa_msg = "", fre_msg = "", ger_msg = "")
	{
		local is_admin_only = (eng_msg.find("[ToAdmin]") != null);

		if(player == null && is_admin_only)
			player = ::rs_cp.getAdmin();

		local GetMessageByLanguage = function(p){
			local lang = Convars.GetClientConvarValue("cl_language", p.GetEntityIndex());
			switch (lang) {
				case "japanese":  	return (jpn_msg  != "") ? jpn_msg  : eng_msg;
				case "korean":
				case "koreana":   	return (kr_msg   != "") ? kr_msg   : eng_msg;
				case "schinese":  	return (sch_msg  != "") ? sch_msg  : eng_msg;
				case "tchinese":  	return (tch_msg  != "") ? tch_msg  : eng_msg;
				case "vietnamese":	return (viet_msg != "") ? viet_msg : eng_msg;
				case "thai":      	return (thai_msg != "") ? thai_msg : eng_msg;
				case "russian":   	return (rus_msg  != "") ? rus_msg  : eng_msg;
				case "spanish":   	return (spa_msg  != "") ? spa_msg  : eng_msg;
				case "french":    	return (fre_msg  != "") ? fre_msg  : eng_msg;
				case "german":    	return (ger_msg  != "") ? ger_msg  : eng_msg;
				default:			return eng_msg;
			}
		};

		if(player != null){
			if(!player.IsValid() || IsPlayerABot(player))
				return;

			local msg = GetMessageByLanguage(player);
			if(msg != "")
				ClientPrint(player, 3, msg);

			return;
		}

		// [ToAdmin] なのに host が取れなかった場合は、全体チャットしない
		if(is_admin_only)
			return;

		for(local surv; surv = Entities.FindByClassname(surv, "player"); ){
			if(!surv.IsValid() || IsPlayerABot(surv))
				continue;

			local msg = GetMessageByLanguage(surv);
			if(msg != "")
				ClientPrint(surv, 3, msg);
		}
	}
}