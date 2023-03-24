#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <unistd.h>

#include "../../../lib_cpp/logs/log.h"
#include "../../../lib_cpp/algorithm/algorithm.h"

#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>

#include "movie.h"

//================================================================================================================================
// CONST
//================================================================================================================================

const int      WND_X_SIZE =  1000;
const int      WND_Y_SIZE =   600;

const double MARIO_X_SIZE =  80.0;
const double MARIO_Y_SIZE = 140.0;

const char *FILE_MUSIC    = "../data/8_bit_music.ogg";
const char *FILE_FONT     = "../data/8_bit_font.ttf" ;
const char *FILE_BACK     = "../data/8_bit_game.jpg" ;
const char *FILE_MARIO    = "../data/mario.png";

const double          g =  9.8; // ускорение свободного падения
const double USER_SPEED =  5.0; // скорость движения по горизонтали
const double USER_JUMP  = 10.0; // скорость сразу после прыжка

//================================================================================================================================
// physics
//================================================================================================================================

#define physics_body (*body)

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_ctor(physics *const body,  const double x_size,
                                        const double y_size, const double  x /* = 0 */, const double  y /* = 0 */,
                                                             const double vx /* = 0 */, const double vy /* = 0 */,
                                                             const double ax /* = 0 */, const double ay /* = 0 */)
{
    log_assert(body != nullptr);

    $x_size = x_size;
    $y_size = y_size;

    return physics_set_param(body, x, y, vx, vy, ax, ay);
}

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_set_param(physics *const body, const double  x /* = 0 */, const double  y /* = 0 */,
                                            const double vx /* = 0 */, const double vy /* = 0 */,
                                            const double ax /* = 0 */, const double ay /* = 0 */)
{
    log_assert(body != nullptr);

    $x  =  x; $y  =  y;
    $vx = vx; $vy = vy;
    $ax = ax; $ay = ay;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool physics_simple_move(physics *const body)
{
    log_assert(body != nullptr);

    $x  += $vx; $y  += $vy;
    $vx += $ax; $vy += $ay;

    return true;
}

//================================================================================================================================
// mario_world
//================================================================================================================================

#define mario_world_character (*mario_life)
#define physics_body          ( $kinematic)

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_ctor(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    physics_ctor(&$kinematic, MARIO_X_SIZE,
                              MARIO_Y_SIZE, 0, (double) WND_Y_SIZE - MARIO_Y_SIZE);
    $direction = MOVE_RIGHT;

    $x_min = 0;
    $x_max = WND_X_SIZE;
    $y_max = WND_Y_SIZE;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_simple_move(mario_world *const mario_life, sf::Sprite *const mario_sprite)
{
    log_verify(mario_life   != nullptr, false);
    log_verify(mario_sprite != nullptr, false);

    if      ($direction == MOVE_LEFT  && $vx > 0) { (*mario_sprite).setScale(-1.0, 1.0); $direction = MOVE_RIGHT; }
    else if ($direction == MOVE_RIGHT && $vx < 0) { (*mario_sprite).setScale(-1.0, 1.0); $direction = MOVE_LEFT;  }

    if (!physics_simple_move(&$kinematic)) return false;

    if      ((int) $x + (int) $x_size < $x_min) $x = $x_max;
    else if ((int) $x                 > $x_max) $x = $x_min - (int) $x_size;
    if      ((int) $y + (int) $y_size > $y_max) $y = $y_max - (int) $y_size;

    (*mario_sprite).setPosition($x, $y);

    return mario_world_reculc_acceleration(mario_life);
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_reculc_acceleration(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    if ((int) $y + (int) $y_size >= $y_max) $ay = 0;
    else                                    $ay = g;
    $ax = 0;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_go_left(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    $vx = (-1) * USER_SPEED;
    return true;
}

bool mario_world_go_right(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    $vx = USER_SPEED;
    return true;
}

bool mario_world_jump(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    if ((int) $y + (int) $y_size >= $y_max) $vy = (-1) * USER_JUMP;
    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_world_stop(mario_world *const mario_life)
{
    log_verify(mario_life != nullptr, false);

    $vx = 0;
    return true;
}

//================================================================================================================================
// mario_handler
//================================================================================================================================

#define mario_handler_exemplar  (*mario)
#define mario_world_caharacter  ($mario_life)
#define physics_body            ($kinematic )

//--------------------------------------------------------------------------------------------------------------------------------

bool mario_handler_ctor(mario_handler *const mario, const char *const mario_file)
{
    log_verify(mario      != nullptr, false);
    log_verify(mario_file != nullptr, false);

    if (!$mario_tex.loadFromFile(mario_file))
    {
        log_error("Can't load mario from file \"%s\"\n", mario_file);
        return false;
    }

    sf::Vector2u mario_initial_size = $mario_tex.getSize();

    $mario_spr.setTexture($mario_tex, true);
    $mario_spr.setScale  (MARIO_X_SIZE / (double) mario_initial_size.x, MARIO_Y_SIZE / (double) mario_initial_size.y);

    return mario_world_ctor(&$mario_life);
}

//================================================================================================================================
// render_text
//================================================================================================================================

#define render_text_str (*str)

//--------------------------------------------------------------------------------------------------------------------------------

bool render_text_ctor(render_text *const str, const char *const   font_file,
                                              const char *const     message,
                                              const unsigned character_size,
                                              const double x_pos,
                                              const double y_pos)
{
    log_verify(str       != nullptr, false);
    log_verify(font_file != nullptr, false);
    log_verify(message   != nullptr, false);

    if (!$msg_font.loadFromFile(font_file))
    {
        log_error("Can't load the font from file \"%s\"\n", font_file);
        return false;
    }

    $msg_text.setFont         ($msg_font);
    $msg_text.setFillColor    (sf::Color::White);

    $msg_text.setString       (message);
    $msg_text.setPosition     (x_pos, y_pos);
    $msg_text.setCharacterSize(character_size);

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool render_text_set_message(render_text *const str, const char *const message)
{
    log_verify(str     != nullptr, false);
    log_verify(message != nullptr, false);

    $msg_text.setString(message);
    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool render_text_progress_bar(render_text *const str, sf::RenderWindow *const wnd)
{
    log_verify(str != nullptr, false);
    log_verify(wnd != nullptr, false);

    char progress[100] = "In progress:..........";
    char *bar_ptr      = progress + 12;

    int cnt = 0;
    do
    {
        $msg_text.setString(progress);

        (*wnd).draw($msg_text);
        (*wnd).display();

        *bar_ptr = '#';
        bar_ptr +=   1;
        cnt++;

        usleep(100);
    }
    while (cnt < 10);

    return true;
}

//================================================================================================================================
// render_back
//================================================================================================================================

#define background (*ground)

//--------------------------------------------------------------------------------------------------------------------------------

bool render_back_ctor(render_back *const ground, const char *const ground_file)
{
    log_verify(ground      != nullptr, false);
    log_verify(ground_file != nullptr, false);

    if (!$back_tex.loadFromFile(ground_file))
    {
        log_error("Can't load background from file \"%s\"\n", ground_file);
        return false;
    }

    sf::Vector2u back_initial_size = $back_tex.getSize();

    $back_spr.setTexture($back_tex, true);
    $back_spr.setScale  (WND_X_SIZE / (double) back_initial_size.x, WND_Y_SIZE / (double) back_initial_size.y);

    return true;
}

//================================================================================================================================
// sf::Music
//================================================================================================================================

bool music_ctor(sf::Music *const music, const char *const music_file)
{
    log_verify(music      != nullptr, false);
    log_verify(music_file != nullptr, false);

    if (!(*music).openFromFile(music_file))
    {
        log_error("Can't load music from file \"%s\"\n", music_file);
        return false;
    }
    return true;
}

//================================================================================================================================
// crack_video
//================================================================================================================================

#define video                   (*crack)
#define render_text_str         $rnd_text
#define background              $rnd_back
#define mario_handler_exemplar  $hero

//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_ctor(crack_video *const crack, sf::RenderWindow *const wnd)
{
    log_verify(crack != nullptr, false);
    log_verify(wnd   != nullptr, false);

    if (!music_ctor        (&$music   , FILE_MUSIC))                                       return false;
    if (!render_text_ctor  (&$rnd_text, FILE_FONT, "Press Esc to crack it!", 50, 350, 20)) return false;
    if (!render_back_ctor  (&$rnd_back, FILE_BACK))                                        return false;
    if (!mario_handler_ctor(&$hero    , FILE_MARIO))                                       return false;

    $music.play();

    (*wnd).draw($back_spr);
    (*wnd).draw($msg_text);
    (*wnd).draw($mario_spr);
    (*wnd).display();

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_window(crack_video *const crack, sf::RenderWindow *const wnd, buffer *const bin_code, const char *const out_file)
{
    log_verify(crack    != nullptr, false);
    log_verify(wnd      != nullptr, false);
    log_verify(bin_code != nullptr, false);
    log_verify(out_file != nullptr, false);

    while ((*wnd).isOpen())
    {
        sf::Event event;
        while ((*wnd).pollEvent(event))
        {
            if (event.type == sf::Event::Closed    ) { (*wnd).close(); buffer_dtor(bin_code); return true; }
            if (event.type == sf::Event::KeyPressed)
            {
                switch(event.key.code)
                {
                    case sf::Keyboard::Space:   mario_world_jump    (&$mario_life); break;
                    case sf::Keyboard::A:       mario_world_go_left (&$mario_life); break;
                    case sf::Keyboard::D:       mario_world_go_right(&$mario_life); break;
                    case sf::Keyboard::Escape:  patch(crack, wnd, bin_code, out_file);
                    default:                    break;
                }
            }
            else if (event.type == sf::Event::KeyReleased)
            {
                switch(event.key.code)
                {
                    case sf::Keyboard::A:
                    case sf::Keyboard::D:   mario_world_stop(&$mario_life);
                    default:                break;
                }
            }

            mario_world_simple_move(&$mario_life, &$mario_spr);

            (*wnd).clear  ();
            (*wnd).draw   ($back_spr);
            (*wnd).draw   ($mario_spr);
            (*wnd).draw   ($msg_text);
            (*wnd).display();

            usleep(10);
        }
    }

    return true;
}