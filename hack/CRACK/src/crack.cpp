#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "../../../lib_cpp/logs/log.h"
#include "../../../lib_cpp/algorithm/algorithm.h"

#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>

//================================================================================================================================
// CONST
//================================================================================================================================

const char      MUSIC_FILE[] = "../data/8_bit_music.ogg";
const char       FONT_FILE[] = "../data/8_bit_font.ttf";
const char BACKGROUND_FILE[] = "../data/8_bit_game.jpg";
const char       HERO_FILE[] = "../data/mario.png";

const unsigned WND_WIDTH  = 1000;
const unsigned WND_HEIGHT =  600;

//================================================================================================================================
// STRUCT crack_video
//================================================================================================================================

struct crack_video
{
    sf::Music   sound_track;
 
    sf::Font    font;
    sf::Text    message;

    sf::Texture back_texture;
    sf::Sprite  back_sprite;

    sf::Texture hero_texture;
    sf::Sprite  hero_sprite;
    bool        hero_is_right_look;
};

//--------------------------------------------------------------------------------------------------------------------------------
// DSL
//--------------------------------------------------------------------------------------------------------------------------------

#define $sound      crack->sound_track

#define $font       crack->font
#define $message    crack->message

#define $back_tex   crack->back_texture
#define $back_spr   crack->back_sprite

#define $hero_tex   crack->hero_texture
#define $hero_spr   crack->hero_sprite
#define $hero_right crack->hero_is_right_look

//================================================================================================================================
// crack_video: FUNCTION DECLARATION
//================================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------
// init
//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_init           (crack_video *const crack, sf::RenderWindow *const wnd);

bool crack_video_music_init     (crack_video *const crack);
bool crack_video_text_init      (crack_video *const crack);
bool crack_video_background_init(crack_video *const crack);
bool crack_video_hero_init      (crack_video *const crack);

//--------------------------------------------------------------------------------------------------------------------------------
// event
//--------------------------------------------------------------------------------------------------------------------------------

void crack_video_event_space    (crack_video *const crack, sf::RenderWindow *const wnd, buffer *const bin_code, const char *const out_file);
void set_cracking_mode          (crack_video *const crack, sf::RenderWindow *const wnd);

void crack_video_event_left     (crack_video *const crack);
void crack_video_event_right    (crack_video *const crack);

//================================================================================================================================
// crack_video: FUNCTION BODY
//================================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------
// init
//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_init(crack_video *const crack, sf::RenderWindow *const wnd)
{
    log_verify(crack != nullptr, false);

    if (!crack_video_music_init     (crack)) return false;
    if (!crack_video_text_init      (crack)) return false;
    if (!crack_video_background_init(crack)) return false;
    if (!crack_video_hero_init      (crack)) return false;

    $sound.play();

    (*wnd).draw   ($back_spr);
    (*wnd).draw   ($hero_spr);
    (*wnd).draw   ($message);
    (*wnd).display();

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_music_init(crack_video *const crack)
{
    log_assert(crack != nullptr);

    if (!$sound.openFromFile(MUSIC_FILE))
    {
        log_error("can't open \"%s\"\n", MUSIC_FILE);
        return false;
    }

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_text_init(crack_video *const crack)
{
    log_assert(crack != nullptr);

    if (!$font.loadFromFile(FONT_FILE))
    {
        log_error("can't open \"%s\"\n", FONT_FILE);
        return false;
    }

    $message.setFont         ($font);
    $message.setString       ("Press space to crack");
    $message.setCharacterSize(50);

    $message.setFillColor(sf::Color::White);
    $message.setPosition (350, 20);

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_background_init(crack_video *const crack)
{
    log_assert(crack != nullptr);

    if (!$back_tex.loadFromFile(BACKGROUND_FILE))
    {
        log_error("can't load \"%s\"\n", BACKGROUND_FILE);
        return false;
    }

    sf::Vector2u tex_sizes = $back_tex.getSize();

    $back_spr.setTexture($back_tex, true);
    $back_spr.setScale  ((float) WND_WIDTH / (float) tex_sizes.x, (float) WND_HEIGHT / (float) tex_sizes.y);

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_hero_init(crack_video *const crack)
{
    log_assert(crack != nullptr);

    if (!$hero_tex.loadFromFile(HERO_FILE))
    {
        log_error("can't load \"%s\"\n", HERO_FILE);
        return false;
    }

    sf::Vector2u tex_sizes = $hero_tex.getSize();

    $hero_spr.setTexture ($hero_tex, true);
    $hero_spr.setScale   (80.0 / (float) tex_sizes.x, 140.0 / tex_sizes.y);
    $hero_spr.setPosition(0                         ,  WND_HEIGHT - 140.0);

    $hero_right = true;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------
// event
//--------------------------------------------------------------------------------------------------------------------------------

void crack_video_event_space(crack_video *const crack, sf::RenderWindow *const wnd, buffer *const bin_code, const char *const out_file)
{
    log_assert(crack != nullptr);
    log_assert(wnd   != nullptr);

    log_assert(bin_code           != nullptr);
    log_assert(bin_code->buff_beg != nullptr);
    log_assert(bin_code->buff_pos != nullptr);

    log_assert(out_file != nullptr);

    static bool is_cracked_alredy = false;
    if (is_cracked_alredy) return;

    set_cracking_mode(crack, wnd);

    FILE *const out_stream = fopen(out_file, "w");
    if (out_stream == nullptr)
    {
        is_cracked_alredy = true;
        $message.setString("Error!(check console)");

        fprintf(stderr, "Can't write in \"%s\"\n", out_file);
        return;
    }

    bin_code->buff_beg[19] = 0xEB;
    bin_code->buff_beg[20] = 0x4D;
    bin_code->buff_beg[21] = 0x90;

    fwrite(bin_code->buff_beg, sizeof(char), bin_code->buff_size, out_stream);
    fclose(out_stream);

    is_cracked_alredy = true;
    $message.setString("Cracking finished!");
}

//--------------------------------------------------------------------------------------------------------------------------------

void set_cracking_mode(crack_video *const crack, sf::RenderWindow *const wnd)
{
    log_assert(crack != nullptr);
    log_assert(wnd   != nullptr);

    $message.setString("Cracking...");

    (*wnd).clear  ();
    (*wnd).draw   ($back_spr);
    (*wnd).draw   ($hero_spr);
    (*wnd).draw   ($message);
    (*wnd).display();
}

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

void crack_video_event_left(crack_video *const crack)
{
    log_verify(crack != nullptr, ;);

    if ($hero_right)
    {
        $hero_spr.scale(-1.0, 1.0);
        $hero_right = false;
    }

    $hero_spr.move(-20, 0);
}

//--------------------------------------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------------------------------------

void crack_video_event_right(crack_video *const crack)
{
    log_verify(crack != nullptr, ;);

    if (!$hero_right)
    {
        $hero_spr.scale(-1.0, 1.0);
        $hero_right = true;
    }

    $hero_spr.move(20, 0);
}

//================================================================================================================================
// FUNCTION DECLARATION
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

    sf::RenderWindow main_wnd(sf::VideoMode(WND_WIDTH, WND_HEIGHT), "CRACK");

    crack_video crack = {};
    if (!crack_video_init(&crack, &main_wnd)) { main_wnd.close(); return 0; }

    while (main_wnd.isOpen())
    {
        sf::Event event;
        while (main_wnd.pollEvent(event))
        {
            if (event.type == sf::Event::Closed    ) { main_wnd.close(); buffer_dtor(&bin_code); return 0; }
            if (event.type == sf::Event::KeyPressed)
            {
                switch(event.key.code)
                {
                    case sf::Keyboard::Space:   crack_video_event_space(&crack, &main_wnd, &bin_code, argv[1]);
                                                break;
                    case sf::Keyboard::A:       crack_video_event_left (&crack);
                                                break;
                    case sf::Keyboard::D:       crack_video_event_right(&crack);
                                                break;
                    default:                    break;
                }
            }

            main_wnd.clear  ();
            main_wnd.draw   (crack.back_sprite);
            main_wnd.draw   (crack.hero_sprite);
            main_wnd.draw   (crack.message);
            main_wnd.display();
        }
    }
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
        fprintf(stderr, "You should give one parameter: file to crack\n");
        return false;
    }

    if (!buffer_ctor_file(bin_code, argv[1])) return false;

    if (!is_correct_file_hash(bin_code))
    {
        fprintf(stderr, "Invalid hash: you gave wrong file or file is damaged\n");

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