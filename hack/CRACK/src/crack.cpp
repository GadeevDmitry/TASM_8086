#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "../../../lib_cpp/logs/log.h"
#include "../../../lib_cpp/algorithm/algorithm.h"

#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>

#include "movie.h"

//================================================================================================================================
// MAIN
//================================================================================================================================

int main(const int argc, const char *argv[])
{
    buffer bin_code = {};
    if (!get_file_to_crack(&bin_code, argc, argv)) return 0;

    sf::RenderWindow main_wnd(sf::VideoMode(WND_X_SIZE, WND_Y_SIZE), "CRACK");
    My_printf_stderr("WINDOW X SIZE: %d\n"
                     "WINDOW Y SIZE: %d\n", WND_X_SIZE, WND_Y_SIZE);

    crack_video crack = {};
    if (!crack_video_ctor(&crack, &main_wnd)) { main_wnd.close(); return 0; }

    crack_video_window(&crack, &main_wnd, &bin_code, argv[1]);
}

//--------------------------------------------------------------------------------------------------------------------------------
// verify
//--------------------------------------------------------------------------------------------------------------------------------

bool get_file_to_crack(buffer *const bin_code, const int argc, const char *argv[])
{
    log_verify(bin_code != nullptr, false);
    log_verify(argv     != nullptr, false);

    log_verify(argc > 0, false);

    if (argc != 2)
    {
        My_printf_stderr("You should give one parameter: file to crack\n");
        return false;
    }

    if (!buffer_ctor_file(bin_code, argv[1])) return false;

    if (!is_correct_file_hash(bin_code))
    {
        My_printf_stderr("Invalid hash: you gave wrong file or file is damaged\n");

        buffer_dtor(bin_code);
        return false;
    }

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool is_correct_file_hash(buffer *const bin_code)
{
    log_assert(bin_code           != nullptr);
    log_assert(bin_code->buff_beg != nullptr);
    log_assert(bin_code->buff_beg == bin_code->buff_pos);

    if (bin_code->buff_size != CORRECT_FILE_SIZE) return false;

    unsigned long long hash_val = 0ll;

    for (; *bin_code->buff_pos; ++bin_code->buff_pos)
    {
        hash_val = ((1 << 5) - 1) * hash_val + (*bin_code->buff_pos);
    }

    bin_code->buff_pos = bin_code->buff_beg;
    return hash_val == CORRECT_HASH_VAL;
}

//--------------------------------------------------------------------------------------------------------------------------------
// patch
//--------------------------------------------------------------------------------------------------------------------------------

void patch(crack_video *const crack, sf::RenderWindow *const wnd, buffer *const bin_code, const char *const out_file)
{
    log_assert(crack != nullptr);
    log_assert(wnd   != nullptr);

    log_assert(bin_code           != nullptr);
    log_assert(bin_code->buff_beg != nullptr);
    log_assert(bin_code->buff_pos != nullptr);

    log_assert(out_file != nullptr);

    static bool is_cracked_alredy = false;
    if (is_cracked_alredy) return;

    FILE *const out_stream = fopen(out_file, "w");
    if (out_stream == nullptr)
    {
        is_cracked_alredy = true;
        render_text_set_message(&(crack->rnd_text), "Error! (Check console)");

        My_printf_stderr("Can't write in \"%s\"\n", out_file);
        return;
    }

    bin_code->buff_beg[19] = 0xEB;
    bin_code->buff_beg[20] = 0x4D;
    bin_code->buff_beg[21] = 0x90;

    fwrite(bin_code->buff_beg, sizeof(char), bin_code->buff_size, out_stream);
    fclose(out_stream);

    is_cracked_alredy = true;

    crack_video_progress_bar(crack, wnd);
    render_text_set_message (&(crack->rnd_text), "Cracking finished!");
}
