obs = obslua

-- Cấu hình thời gian
work_time = 45 * 60
break_time = 10 * 60  
current_round = 0 
is_working = true  
is_running = false
time_left = work_time  

-- Các Source trong OBS
source_timer = "Pomodoro Timer"
source_rounds = "Pomodoro Target"  

-- Hàm phát âm thanh khi kết thúc Work Time hoặc Break Time
function play_sound()
    local sound_file = "D:\\Setup\\obs-studio\\buzz-pomodoro.wav" -- Đường dẫn đến file âm thanh

    -- Kiểm tra file có tồn tại không
    local file = io.open(sound_file, "r")
    if file == nil then
        print("[ERROR] Không tìm thấy file âm thanh: " .. sound_file)
        return
    end
    file:close()

    -- Chạy PowerShell để phát âm thanh
    os.execute('cmd /c start /min powershell -WindowStyle Hidden -c "(New-Object Media.SoundPlayer \\"D:\\Setup\\obs-studio\\buzz-pomodoro.wav\\").PlaySync()"')

end


-- Lấy số vòng mục tiêu từ OBS
function get_target_rounds()
    local rounds_source = obs.obs_get_source_by_name(source_rounds)
    if rounds_source ~= nil then
        local settings = obs.obs_source_get_settings(rounds_source)
        local target_text = obs.obs_data_get_string(settings, "text")
        obs.obs_data_release(settings)
        obs.obs_source_release(rounds_source)
        return tonumber(target_text) or 3
    end
    return 3
end

-- Cập nhật hiển thị OBS
function update_display()
    local text_source = obs.obs_get_source_by_name(source_timer)
    if text_source ~= nil then
        local settings = obs.obs_data_create()
        local minutes = math.floor(time_left / 60)
        local seconds = time_left % 60
        local target_rounds = get_target_rounds()

        -- Hiển thị trạng thái
        local status_text = is_working and "Work Time" or "Break Time"
        local progress_text = string.format("Pomodoro: %d/%d", current_round, target_rounds)
        local display_text = string.format("%02d:%02d", minutes, seconds)

        if current_round >= target_rounds then
            progress_text = "COMPLETE!"
            is_running = false
            play_sound()  -- Phát âm thanh khi hoàn thành Pomodoro
        end

        obs.obs_data_set_string(settings, "text", progress_text .. "\n" .. status_text .. "\n" .. display_text)
        obs.obs_source_update(text_source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(text_source)
    end
end

-- Cập nhật timer mỗi giây
function update_timer()
    if not is_running then return end  

    if time_left <= 0 then
        play_sound()  -- 🔊 Phát âm thanh khi đổi trạng thái (Hết Work/Break)

        if is_working then
            time_left = break_time
            current_round = current_round + 1
        else
            time_left = work_time
        end
        is_working = not is_working
    end

    if current_round >= get_target_rounds() then
        is_running = false
        play_sound()  -- 🔊 Phát âm thanh khi kết thúc toàn bộ Pomodoro
    end

    update_display()
    time_left = time_left - 1
end

-- Bắt đầu/dừng Pomodoro
function start_pomodoro(pressed)
    if pressed then
        is_running = not is_running
        if is_running then
            play_sound() -- 🔊 Kêu ngay khi bấm bắt đầu Pomodoro
        end
    end
end

-- Reset Pomodoro
function reset_pomodoro(pressed)
    if pressed then
        is_running = false
        is_working = true
        current_round = 0
        time_left = work_time
        update_display()
    end
end

-- Đăng ký hotkey trong OBS
function script_load(settings)
    obs.timer_add(update_timer, 1000) 
    hotkey_id = obs.obs_hotkey_register_frontend("start_pomodoro", "Start Pomodoro", start_pomodoro)
    hotkey_reset = obs.obs_hotkey_register_frontend("reset_pomodoro", "Reset Pomodoro", reset_pomodoro)

    hotkey_save_array = obs.obs_data_get_array(settings, "hotkey_start")
    obs.obs_hotkey_load(hotkey_id, hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    hotkey_reset_array = obs.obs_data_get_array(settings, "hotkey_reset")
    obs.obs_hotkey_load(hotkey_reset, hotkey_reset_array)
    obs.obs_data_array_release(hotkey_reset_array)
end

-- Lưu hotkey vào cài đặt OBS
function script_save(settings)
    hotkey_save_array = obs.obs_hotkey_save(hotkey_id)
    obs.obs_data_set_array(settings, "hotkey_start", hotkey_save_array)
    obs.obs_data_array_release(hotkey_save_array)

    hotkey_reset_array = obs.obs_hotkey_save(hotkey_reset)
    obs.obs_data_set_array(settings, "hotkey_reset", hotkey_reset_array)
    obs.obs_data_array_release(hotkey_reset_array)
end
