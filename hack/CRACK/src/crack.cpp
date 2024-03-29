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
// FUNCTION_DECLARATION
//================================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------
// verify
//--------------------------------------------------------------------------------------------------------------------------------

const unsigned long long CORRECT_HASH_VAL  = 0xFFFFFFFFFFFFFD1D;
const size_t             CORRECT_FILE_SIZE = 236;

bool get_file_to_crack   (buffer *const bin_code, const int argc, const char *argv[]);
bool is_correct_file_hash(buffer *const bin_code);

//================================================================================================================================
// MAIN
//================================================================================================================================

int main(const int argc, const char *argv[])
{
    buffer bin_code = {};
    if (!get_file_to_crack(&bin_code, argc, argv)) return 0;

    sf::RenderWindow main_wnd(sf::VideoMode((unsigned) WND_X_SIZE, (unsigned) WND_Y_SIZE), "CRACK");
    My_printf_stderr("%d %s %x %d%%%c%b\n"
                     "WINDOW X SIZE: %d\n"
                     "WINDOW Y SIZE: %d\n", -1LL, "LOVE", 3802LL, 100LL, 33LL, 127LL, WND_X_SIZE, WND_Y_SIZE);

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
        hash_val = ((1 << 5) - 1) * hash_val + (long long unsigned) (*bin_code->buff_pos);
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

    bin_code->buff_beg[19] = '\xEB';
    bin_code->buff_beg[20] = '\x4D';
    bin_code->buff_beg[21] = '\x90';

    fwrite(bin_code->buff_beg, sizeof(char), bin_code->buff_size, out_stream);
    fclose(out_stream);

    is_cracked_alredy = true;

    crack_video_progress_bar(crack, wnd);
    render_text_set_message (&(crack->rnd_text), "Cracking finished!");
}
