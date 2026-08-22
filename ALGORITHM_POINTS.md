# How the program places the points

## The idea

![marilyn_progress](docs/marilyn_progress.gif)

It starts from a single point at the centre, then makes new points "sprout"
around each point already placed, a bit like a plant growing branches or a
colony of bacteria spreading in every direction — until the whole page is
filled.

Where the image is dark, points are allowed to crowd closer together; where
it's bright, they have to stay further apart (or don't appear at all). This
distance rule is, in the end, what makes the picture emerge.

## Step by step

1. **A first point at the centre.**
   This point is added to a list of "active" points — points that are still
   allowed to spawn neighbours.

2. **An active point is picked at random** from that list, and the program
   tries to find it a neighbour.

3. **A candidate neighbour is drawn at a random distance**, in a random
   direction too (an angle picked at random over 360°). The distance isn't
   entirely free: it's drawn from a range that depends on the density wanted
   at that spot (see below).

4. **The candidate is checked for validity:**
   - It must stay within the page's bounds.
   - The image pixel at that spot must not be too bright (otherwise,
     immediate rejection — that's the "threshold").
   - It must be far enough from *every* point already placed around it. The
     minimum required distance itself depends on how bright the pixel is at
     that spot: dark → points can be close together; bright → more space is
     needed.

5. **If the candidate is valid**, it becomes a newly placed point, and it in
   turn joins the list of active points (it will be able to spawn its own
   neighbours later on).

6. **The program retries several times** (7 attempts) before giving up on an
   active point. If none of the 7 candidates works out, that point is
   removed from the active list: it's done sprouting, no more neighbours
   will be sought around it.

7. **This repeats**, picking another active point at random, over and over,
   until there are no active points left. At that point, the whole page has
   been explored and filled as best it can be: generation is done.

## Special case: the first point skips the rule

The very first point, the one placed at the centre in step 1, does **not**
go through the step 4 check: it is placed without looking at what the image
says at that spot. Even if the centre of the image is bright enough that no
point would normally be allowed there (too bright, or beyond the
"threshold"), that centre point still gets drawn.

It still joins the list of active points and tries to spawn neighbours
normally, with the real rule this time. If the area around the centre is too
bright to allow any valid neighbour at all, all 7 of its attempts fail, it
gets removed from the active list, and it stays alone: the result is an
isolated point at the centre of the image, even in an area that should have
stayed completely empty.

## Why density varies across the image

Every time a candidate is tested, the program looks at the value of the
image pixel at that exact spot (bright or dark) and computes a custom-fit
minimum distance:

- **Density**: the base setting — the higher it is, the closer points can be
  packed in dark areas.
- **Contrast**: the gap between the spacing in dark areas and the spacing in
  bright areas. A higher contrast sharpens the difference between dense and
  empty areas.
- **Gamma**: how the transition between dark and bright unfolds — more
  gradual or more abrupt through the midtones.
- **Min value / Max value**: the bounds below / above which a pixel is
  treated as fully black / fully white.
- **Threshold (hard cutoff)**: beyond this brightness, no point is placed at
  all — the area stays blank.
- **Invert**: flips the rule, making bright areas dense instead of dark
  ones.

## A clever trick (not essential to understand): the grid

To avoid comparing every new candidate against *all* the points already
placed (which would get very slow once there are thousands of them), the
program stores points in an invisible grid. When it tests a candidate, it
only looks at the points filed in the neighbouring cells. It's a speed
trick — it changes nothing about the visual result.

## The seed

The randomness used to pick distances and angles is actually generated from
a starting number, the "seed". With the same image and the same seed, you
get exactly the same point cloud every time — which makes it possible to
reproduce or compare results. Changing the seed gives a new layout, while
keeping the same overall look (the same recognisable image, just "seeded"
differently).

---

*This document is a first pass at a plain-English explanation — to be
refined based on whatever details readers find most interesting (Poisson
Disk Sampling as a technique, GUI settings, etc.).*
