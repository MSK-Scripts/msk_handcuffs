Translate = function(locale, ...)
    if ... then
        return Translation[Config.Locale][locale]:format(...)
    end
    
    return Translation[Config.Locale][locale]
end

Translation = {
    ['de'] = {
        ['admin_cuff'] = 'Der Spieler mit der ~g~ID %s~s~ wird gefesselt',
        ['admin_hardcuff'] = 'Der Spieler mit der ~g~ID %s~s~ wird hart gefesselt',
        ['admin_uncuff'] = 'Der Spieler mit der ~g~ID %s~s~ wird entfesselt',
        ['admin_ankletracker_activated'] = 'Die elektronische Fußfessel wurde für den Spieler mit der ~g~ID %s~s~ aktiviert',
        ['admin_ankletracker_deactivated'] = 'Die elektronische Fußfessel wurde für den Spieler mit der ~g~ID %s~s~ deaktiviert',
        ['admin_headbag_activated'] = 'Dem Spieler mit der ~g~ID %s~s~ wird ein Sack über den Kopf gezogen',
        ['admin_headbag_deactivated'] = 'Dem Spieler mit der ~g~ID %s~s~ wird der Sack vom Kopf entfernt',
        ['admin_tape_activated'] = 'Dem Spieler mit der ~g~ID %s~s~ wird ein Tape auf den Mund geklebt',
        ['admin_tape_deactivated'] = 'Dem Spieler mit der ~g~ID %s~s~ wird das Tape vom Mund entfernt',

        ['no_player_nearby'] = 'Es ist kein Spieler in der Nähe',

        ['target_cuff'] = 'Fesseln',
        ['target_hardcuff'] = 'Hart fesseln',
        ['target_uncuff'] = 'Entfesseln',
        ['target_ankletracker_on'] = 'Fußfessel anlegen',
        ['target_ankletracker_off'] = 'Fußfessel entfernen',
        ['target_headbag_on'] = 'Sack aufsetzen',
        ['target_headbag_off'] = 'Sack abnehmen',
        ['target_tape_on'] = 'Mund zukleben',
        ['target_tape_off'] = 'Mund freimachen',
        ['target_drag'] = 'Ziehen / Eskortieren',
        ['target_putincar'] = 'Ins Fahrzeug setzen',
        ['target_putoutofcar'] = 'Aus Fahrzeug holen',

        ['player_set_headbag'] = 'Du hast dem Spieler einen Sack auf dem Kopf gesetzt',
        ['player_remove_headbag'] = 'Du hast dem Spieler den Sack vom Kopf entfernt',
        ['player_has_no_headbag'] = 'Der Spieler hat keinen Sack auf dem Kopf!',
        ['player_already_has_headbag'] = 'Der Spieler hat bereits einen Sack auf dem Kopf!',

        ['player_set_tape'] = 'Du hast dem Spieler ein Klebeband auf dem Mund gesetzt',
        ['player_remove_tape'] = 'Du hast dem Spieler das Klebeband vom Mund entfernt',
        ['player_taped'] = 'Du hast dem Spieler ein Klebeband auf dem Mund geklebt',
        ['player_has_no_tape'] = 'Der Spieler hat kein Klebeband auf dem Mund!',
        ['player_already_has_tape'] = 'Der Spieler hat bereits ein Klebeband auf dem Mund!',

        ['player_uncuffed'] = 'Du hast den Spieler entfesselt',
        ['has_no_handcuffs'] = 'Der Spieler muss erst gefesselt werden.',
        ['uncuffed_timer'] = 'Du wurdest automatisch entfesselt',
        ['drag_not_handcuffed'] = 'Du kannst eine nicht gefesselte Person nicht tragen',
        ['escort_release'] = 'Drücke um die Person loszulassen',
        ['wrong_uncuff_item'] = 'Du kannst die Person mit diesem Item nicht entfesseln!',
        ['player_not_handcuffed'] = 'Der Spieler ist nicht gefesselt',
        ['player_already_cuffed'] = 'Der Spieler ist bereits gefesselt',
        
        ['not_hasItem'] = 'Du hast kein passendes Item dabei',
        ['not_hasItem_named'] = 'Du benötigst folgendes Item: ~y~%s',
        ['not_hasItem_cuff'] = 'Du hast kein Item um jemanden zu fesseln',
        ['not_hasItem_hardcuff'] = 'Du hast kein Item um jemanden Hart zu fesseln',
        ['not_hasItem_uncuff'] = 'Du hast kein Item um jemanden zu entfesseln',

        ['ankletracker_activated'] = 'Elektronische Fußfessel aktiviert',
        ['ankletracker_deactivated'] = 'Elektronische Fußfessel deaktiviert',
        ['tape_activated'] = 'Dir wurde ein Tape über den Mund geklebt, du kannst nun nicht mehr sprechen',
        ['tape_deactivated'] = 'Dir wurde das Tape vom Mund entfernt, du kannst nun wieder sprechen',

        ['not_allowed'] = 'Diese Aktion ist dir untersagt!',
        ['no_dashboard_permission'] = 'Du hast keine Berechtigung für das Admin-Dashboard.',
    },
    ['en'] = {
        ['admin_cuff'] = 'The Player with ~g~ID %s~s~ is cuffed',
        ['admin_hardcuff'] = 'the Player with ~g~ID %s~s~ is hardcuffed',
        ['admin_uncuff'] = 'The Player with ~g~ID %s~s~ is uncuffed',
        ['admin_ankletracker_activated'] = 'The Ankletracker has been activated for Player with ~g~ID %s~s~',
        ['admin_ankletracker_deactivated'] = 'The Ankletracker has been deactivated for Player with ~g~ID %s~s~',
        ['admin_headbag_activated'] = 'The player with the ~g~ID %s~s~ has a headbag pulled over his head',
        ['admin_headbag_deactivated'] = 'The headbag is removed from the head of the player with the ~g~ID %s~s~',
        ['admin_tape_activated'] = 'The player with the ~g~ID %s~s~ has a tape stuck to his mouth',
        ['admin_tape_deactivated'] = 'The tape on the mouth of the player with the ~g~ID %s~s~ is removed',

        ['no_player_nearby'] = 'There is no player nearby',

        ['target_cuff'] = 'Cuff',
        ['target_hardcuff'] = 'Hardcuff',
        ['target_uncuff'] = 'Uncuff',
        ['target_ankletracker_on'] = 'Attach ankletracker',
        ['target_ankletracker_off'] = 'Remove ankletracker',
        ['target_headbag_on'] = 'Put on headbag',
        ['target_headbag_off'] = 'Remove headbag',
        ['target_tape_on'] = 'Tape mouth',
        ['target_tape_off'] = 'Remove tape',
        ['target_drag'] = 'Drag / Escort',
        ['target_putincar'] = 'Put in vehicle',
        ['target_putoutofcar'] = 'Get out of vehicle',

        ['player_headbaged'] = 'You put a sack on the players head',
        ['player_has_no_headbag'] = 'The player does not have a sack on their head.',
        ['player_already_has_headbag'] = 'The player already has a sack on their head!',

        ['player_taped'] = 'You taped the players mouth',
        ['player_has_no_tape'] = 'The player does not have tape on their mouth!',
        ['player_already_has_tape'] = 'The player already has tape on their mouth!',

        ['player_uncuffed'] = 'You uncuffed the player',
        ['has_no_handcuffs'] = 'The Player has to be cuffed first.',
        ['uncuffed_timer'] = 'You were automatically uncuffed',
        ['drag_not_handcuffed'] = "You can't drag someone who isn't handcuffed",
        ['escort_release'] = 'Press to release the person',
        ['wrong_uncuff_item'] = 'You cannot uncuff the person with this item!',
        ['player_not_handcuffed'] = 'The Player is not cuffed',
        ['player_already_cuffed'] = 'Player is already cuffed',

        ['not_hasItem'] = 'You don\'t have the correct item',
        ['not_hasItem_named'] = 'You need this item: ~y~%s',
        ['not_hasItem_cuff'] = 'You don\'t have the correct item to cuff someone',
        ['not_hasItem_hardcuff'] = 'You don\'t have the correct item to hardcuff someone',
        ['not_hasItem_uncuff'] = 'You don\'t have the correct item to uncuff someone',

        ['ankletracker_activated'] = 'Ankletracker activated',
        ['ankletracker_deactivated'] = 'Ankletracker deactivated',
        ['tape_activated'] = 'A tape was put over your mouth, you can no longer speak',
        ['tape_deactivated'] = 'The tape has been removed from your mouth, you can now speak again',

        ['not_allowed'] = 'You are not allowed to do that!',
        ['no_dashboard_permission'] = 'You do not have permission for the admin dashboard.',
    },
    ['hu'] = {
        ['admin_cuff'] = 'A(z) ~g~%s ID-jú~s~ játékos meg lett bilincselve',
        ['admin_hardcuff'] = 'A(z) ~g~%s ID-jú~s~ játékos szorosan meg lett bilincselve',
        ['admin_uncuff'] = 'A(z) ~g~%s ID-jú~s~ játékos bilincse le lett véve',
        ['admin_ankletracker_activated'] = 'A nyomkövető bokaperec aktiválva lett a(z) ~g~%s ID-jú~s~ játékoson',
        ['admin_ankletracker_deactivated'] = 'A nyomkövető bokaperec deaktiválva lett a(z) ~g~%s ID-jú~s~ játékoson',
        ['admin_headbag_activated'] = 'A(z) ~g~%s ID-jú~s~ játékos fejére egy zsákot húztak',
        ['admin_headbag_deactivated'] = 'A zsák el lett távolítva a(z) ~g~%s ID-jú~s~ játékos fejéről',
        ['admin_tape_activated'] = 'A(z) ~g~%s ID-jú~s~ játékos szája le lett ragasztva',
        ['admin_tape_deactivated'] = 'A ragasztószalag el lett távolítva a(z) ~g~%s ID-jú~s~ játékos szájáról',

        ['no_player_nearby'] = 'Nincs játékos a közeledben',

        ['target_cuff'] = 'Bilincs',
        ['target_hardcuff'] = 'Erős bilincs',
        ['target_uncuff'] = 'Bilincs le',
        ['target_ankletracker_on'] = 'Nyomkövető felhelyezése',
        ['target_ankletracker_off'] = 'Nyomkövető eltávolítása',
        ['target_headbag_on'] = 'Zsák felhelyezése',
        ['target_headbag_off'] = 'Zsák levétele',
        ['target_tape_on'] = 'Száj leragasztása',
        ['target_tape_off'] = 'Ragasztó eltávolítása',
        ['target_drag'] = 'Húzás / Kísérés',
        ['target_putincar'] = 'Autóba ültetés',
        ['target_putoutofcar'] = 'Autóból kihúzás',

        ['player_headbaged'] = 'Zsákot húztál a játékos fejére',
        ['player_has_no_headbag'] = 'Nincs zsák a játékos fején.',
        ['player_already_has_headbag'] = 'Már van zsák a játékos fején!',

        ['player_taped'] = 'Leragasztottad a játékos száját',
        ['player_has_no_tape'] = 'A játékos szája nincs leragasztva!',
        ['player_already_has_tape'] = 'A játékos szája már le van ragasztva!',

        ['player_uncuffed'] = 'Levetted a bilincset a játékosról',
        ['has_no_handcuffs'] = 'A játékosnak előbb bilincsben kell lennie.',
        ['uncuffed_timer'] = 'A bilincsed automatikusan lekerült',
        ['drag_not_handcuffed'] = "Nem kísérhetsz/húzhatsz olyat, aki nincs megbilincselve",
        ['escort_release'] = 'Nyomd meg a személy elengedéséhez',
        ['wrong_uncuff_item'] = 'Ezzel a tárggyal nem tudod levágni/levenni a bilincset a személyről!',
        ['player_not_handcuffed'] = 'A játékos nincs megbilincselve',
        ['player_already_cuffed'] = 'A játékos már meg van bilincselve',

        ['not_hasItem'] = 'Nincs nálad a megfelelő tárgy',
        ['not_hasItem_named'] = 'Ehhez a következő tárgy kell: ~y~%s',
        ['not_hasItem_cuff'] = 'Nincs nálad a bilincseléshez szükséges tárgy',
        ['not_hasItem_hardcuff'] = 'Nincs nálad a szoros bilincseléshez szükséges tárgy',
        ['not_hasItem_uncuff'] = 'Nincs nálad a bilincs levételéhez szükséges tárgy',

        ['ankletracker_activated'] = 'Nyomkövető bokaperec aktiválva',
        ['ankletracker_deactivated'] = 'Nyomkövető bokaperec deaktiválva',
        ['tape_activated'] = 'Ragasztószalagot tettek a szádra, már nem tudsz beszélni',
        ['tape_deactivated'] = 'A ragasztószalagot levették a szádról, most már újra beszélhetsz',

        ['not_allowed'] = 'Ehhez nincs jogosultságod / Ezt nem teheted meg!',
        ['no_dashboard_permission'] = 'Nincs jogosultságod az admin irányítópulthoz.',
    },
}
