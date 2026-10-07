-- SAM timer – UI strings (en, cs, sk, hu)
-- Loaded by main.lua. When adding a new string, add it to every language;
-- any missing key falls back to English.

local translations = {
    en = {
        name = "SAM timer", round = "Round", flyoff = "Fly-off", fo = "FO", done = "Done",
        total = "Total", points = "pts", noSwitch = "Set a start switch",
        running = "RUN", stopped = "STOP",
        cfgSwitch = "Start/stop switch", cfgReset = "Reset switch",
        cfgRounds = "Number of rounds", cfgFlyoff = "Fly-off round", cfgMax = "Max time (round)",
        cfgFoMax = "Max time (fly-off)", cfgMinCall = "Call out each minute", cfgMaxAlert = "Alert at max time",
        cfgMinTime = "Min. recorded time", cfgColors = "Colors", cfgDrop = "Drop lowest round",
        cfgMotor = "Motor run time", cfgMotorWarn = "Motor pre-warning", cfgMotorCol = "Motor",
        motor = "MOTOR", motorOff = "MOTOR OFF!", motorIdle = "Motor run",
        cfgBg = "Background", cfgText = "Text", cfgRun = "Running time", cfgOver = "Max marker", cfgSel = "Current round",
        mReset = "New contest (clear all)",
        mPrev = "Previous round", mNext = "Next round",
    },
    cs = {
        name = "SAM časoměřič", round = "Kolo", flyoff = "Rozlet", fo = "FO", done = "Hotovo",
        total = "Celkem", points = "bodů", noSwitch = "Nastavte spínač startu",
        running = "BĚŽÍ", stopped = "STOP",
        cfgSwitch = "Spínač start/stop", cfgReset = "Spínač nulování",
        cfgRounds = "Počet kol", cfgFlyoff = "Rozletové kolo", cfgMax = "Max. čas (kolo)",
        cfgFoMax = "Max. čas (rozlet)", cfgMinCall = "Hlásit každou minutu", cfgMaxAlert = "Upozornit na max. čas",
        cfgMinTime = "Min. zaznamenaný čas", cfgColors = "Barvy", cfgDrop = "Škrtat nejhorší kolo",
        cfgMotor = "Doba chodu motoru", cfgMotorWarn = "Předběžné varování motoru", cfgMotorCol = "Motor",
        motor = "MOTOR", motorOff = "MOTOR VYP!", motorIdle = "Chod motoru",
        cfgBg = "Pozadí", cfgText = "Text", cfgRun = "Běžící čas", cfgOver = "Značka max.", cfgSel = "Aktuální kolo",
        mReset = "Nová soutěž (smazat vše)",
        mPrev = "Předchozí kolo", mNext = "Další kolo",
    },
    sk = {
        name = "SAM časomerač", round = "Kolo", flyoff = "Rozlet", fo = "FO", done = "Hotovo",
        total = "Spolu", points = "bodov", noSwitch = "Nastavte spínač štartu",
        running = "BEŽÍ", stopped = "STOP",
        cfgSwitch = "Spínač štart/stop", cfgReset = "Spínač nulovania",
        cfgRounds = "Počet kôl", cfgFlyoff = "Rozletové kolo", cfgMax = "Max. čas (kolo)",
        cfgFoMax = "Max. čas (rozlet)", cfgMinCall = "Hlásiť každú minútu", cfgMaxAlert = "Upozorniť na max. čas",
        cfgMinTime = "Min. zaznamenaný čas", cfgColors = "Farby", cfgDrop = "Škrtať najhoršie kolo",
        cfgMotor = "Doba chodu motora", cfgMotorWarn = "Predbežné varovanie motora", cfgMotorCol = "Motor",
        motor = "MOTOR", motorOff = "MOTOR VYP!", motorIdle = "Chod motora",
        cfgBg = "Pozadie", cfgText = "Text", cfgRun = "Bežiaci čas", cfgOver = "Značka max.", cfgSel = "Aktuálne kolo",
        mReset = "Nová súťaž (vymazať všetko)",
        mPrev = "Predchádzajúce kolo", mNext = "Ďalšie kolo",
    },
    hu = {
        name = "SAM időmérő", round = "Menet", flyoff = "Flyoff", fo = "FO", done = "Kész",
        total = "Összesen", points = "pont", noSwitch = "Állíts be start kapcsolót",
        running = "MÉR", stopped = "ÁLL",
        cfgSwitch = "Start/stop kapcsoló", cfgReset = "Nullázó kapcsoló",
        cfgRounds = "Alapmenetek száma", cfgFlyoff = "Flyoff menet", cfgMax = "Max. idő (menet)",
        cfgFoMax = "Max. idő (flyoff)", cfgMinCall = "Percenkénti bemondás", cfgMaxAlert = "Jelzés max. időnél",
        cfgMinTime = "Min. mérhető idő", cfgColors = "Színek", cfgDrop = "Legkisebb menet kiesik",
        cfgMotor = "Motoridő", cfgMotorWarn = "Motor előjelzés", cfgMotorCol = "Motor",
        motor = "MOTOR", motorOff = "MOTOR LE!", motorIdle = "Motoridő",
        cfgBg = "Háttér", cfgText = "Szöveg", cfgRun = "Futó idő", cfgOver = "Max. jelölés", cfgSel = "Aktuális menet",
        mReset = "Új verseny (minden törlése)",
        mPrev = "Előző menet", mNext = "Következő menet",
    },
}

translations.cz = translations.cs -- for the legacy / non-standard locale code

-- fall back to English for any missing string
for code, t in pairs(translations) do
    if code ~= "en" then setmetatable(t, { __index = translations.en }) end
end

return translations
