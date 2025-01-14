#include <iostream>
// #define SDL_MAIN_HANDLED
#include <SDL.h>
using namespace std;
int main(int argc, char **argv)
{
	SDL_Init(SDL_INIT_EVERYTHING);
	SDL_Window* window = SDL_CreateWindow(
		"Test SDL",
		SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
		800, 600, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
	
	SDL_Event event;
	bool closed = false;
	while(!closed)
	{
		while(SDL_PollEvent(&event))
		{
			if(event.type == SDL_QUIT)
			{
				closed = true;
			}
		}
	}
	
	SDL_DestroyWindow(window);
	SDL_Quit();
	return 0;
}