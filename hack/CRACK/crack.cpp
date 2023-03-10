#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <math.h>

#include "../lib_cpp/logs/log.h"
#include "../lib_cpp/algorithm/algorithm.h"

#include <SFML/Graphics.hpp>
#include <SFML/Audio.hpp>

//================================================================================================================================
// CONST
//================================================================================================================================

const char     MUSIC_FILE[] = "8_bit_music.ogg";

const char     BACKGROUND_FILE [] = "8_bit_game.jpg";
const unsigned BACKGROUND_WIDTH   = 626;                // ширина фона в пикселях
const unsigned BACKGROUND_HEIGHT  = 289;                // высота фона в пикселях

const char     HERO_FILE [] = "mario.png";
const unsigned HERO_WIDTH   =  672;                     // ширина героя в пикселях
const unsigned HERO_HEIGHT  = 1176;                     // высота героя в пикселях

const unsigned WND_WIDTH  = 1000;
const unsigned WND_HEIGHT =  600;

//================================================================================================================================
// STRUCT crack_video
//================================================================================================================================

struct crack_video
{
    sf::Music   sound_track;

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

#define $back_tex   crack->back_texture
#define $back_spr   crack->back_sprite

#define $hero_tex   crack->hero_texture
#define $hero_spr   crack->hero_sprite
#define $hero_right crack->hero_is_right_look

//================================================================================================================================
// FUNCTION DECLARATION
//================================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------
// init
//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_init           (crack_video *const crack, sf::RenderWindow *const wnd);

bool crack_video_music_init     (crack_video *const crack);
bool crack_video_background_init(crack_video *const crack);
bool crack_video_hero_init      (crack_video *const crack);

//--------------------------------------------------------------------------------------------------------------------------------
// event
//--------------------------------------------------------------------------------------------------------------------------------

void crack_video_event_left     (crack_video *const crack);
void crack_video_event_right    (crack_video *const crack);

//================================================================================================================================
// FUNCTION BODY
//================================================================================================================================

//--------------------------------------------------------------------------------------------------------------------------------
// init
//--------------------------------------------------------------------------------------------------------------------------------

bool crack_video_init(crack_video *const crack, sf::RenderWindow *const wnd)
{
    log_verify(crack != nullptr, false);

    if (!crack_video_music_init     (crack)) return false;
    if (!crack_video_background_init(crack)) return false;
    if (!crack_video_hero_init      (crack)) return false;

    $sound.play();

    (*wnd).draw   ($back_spr);
    (*wnd).draw   ($hero_spr);
    (*wnd).display();

    return true;
}

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

bool crack_video_background_init(crack_video *const crack)
{
    log_assert(crack != nullptr);

    if (!$back_tex.loadFromFile(BACKGROUND_FILE))
    {
        log_error("can't load \"%s\"\n", BACKGROUND_FILE);
        return false;
    }

    $back_spr.setTexture($back_tex, true);
    $back_spr.setScale  ((float) WND_WIDTH / (float) BACKGROUND_WIDTH, (float) WND_HEIGHT / (float) BACKGROUND_HEIGHT);

    return true;
}

bool crack_video_hero_init(crack_video *const crack)
{
    log_assert(crack != nullptr);

    if (!$hero_tex.loadFromFile(HERO_FILE))
    {
        log_error("can't load \"%s\"\n", HERO_FILE);
        return false;
    }

    $hero_spr.setTexture ($hero_tex, true);
    $hero_spr.setScale   (80.0 / HERO_WIDTH, 140.0 / HERO_HEIGHT);
    $hero_spr.setPosition(0                ,  WND_HEIGHT - 140.0);

    $hero_right = true;

    return true;
}

//--------------------------------------------------------------------------------------------------------------------------------
// event
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
// MAIN
//================================================================================================================================

int main()
{
    sf::RenderWindow main_wnd(sf::VideoMode(WND_WIDTH, WND_HEIGHT), "CRACK");

    crack_video crack = {};
    if (!crack_video_init(&crack, &main_wnd)) { main_wnd.close(); return 0; }

    while (main_wnd.isOpen())
    {
        sf::Event event;
        while (main_wnd.pollEvent(event))
        {
            if (event.type == sf::Event::Closed    ) { main_wnd.close(); return 0; }
            if (event.type == sf::Event::KeyPressed)
            {
                switch(event.key.code)
                {
                    case sf::Keyboard::A:   crack_video_event_left (&crack);
                                            break;
                    case sf::Keyboard::D:   crack_video_event_right(&crack);
                                            break;
                    default:                break;
                }
            }

            main_wnd.clear  ();
            main_wnd.draw   (crack.back_sprite);
            main_wnd.draw   (crack.hero_sprite);
            main_wnd.display();
        }
    }
}