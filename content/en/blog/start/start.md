---
title: "Deploying This Site to Github Pages"
date: 2020-10-19T10:27:06-05:00
tags: ["Actions","Hugo","Github"]
---

## The Start of this Site

A while ago I joined a lot of developer and tech communities and noticed that there's a lot of people building really nice personal websites, so I thought I should probably do the same.  I've never been a super creative or visual person and have carved out my career as more of a backend engineer. So I decided to go with a static site generator and had some familiarity with Hugo.  I poked around a bunch of hugo themes and eventually found [this somewhat minimalist theme](https://themes.gohugo.io/hugo-theme-introduction/) that really sparked an interest in me.  So I went ahead and downloaded it and set up my initial website.  I did somewhat edit the theme to add the skills section you see [here](https://brentgruber.github.io/#skills) and also to add the download resume button directly under my beautiful mug. you can find all the edits under /themes/introduction/layouts in the source repository [here](https://github.com/BrentGruber/BrentGruber.github.io/tree/master/themes/introduction/layouts)


## Initial Deployment

Now that I had a basic site with all my information filled in I needed a way to deploy it and share it with the world.  I examined a couple options to start with

1. Github Pages

2. A droplet on digital ocean with nginx or a similar reverse proxy software

3. Self hosting


At the time I first started working on the website I had a slight obsession with trying to host everything myself on my own hardware.  So I decided to light a candle with a flamethrower and host my own gitlab server.

I went ahead and set aside some resources on my overpowered gaming desktop and provisioned a 2x4 ubuntu vm using Windows Hyper-V.  I set gitlab up, set up a runner for the gitlab CI, and set up a workflow for my repo.  I got my first successful workflow and deploy to my local gitlab pages, but now I just needed a way to expose the site to the internet.  I provisioned a [Digital Ocean*](https://m.do.co/c/ab7362a9821f) droplet and installed Caddy on it with the intention to use it as a reverse proxy into the gitlab pages site running on my vm.  I was able to do this by connecting both the droplet and the vm to a wireguard network and setting up caddy to reverse proxy my subdomain (portfolio.brentgruber.com) to the vm on my home network.  Bonus points because Caddy provided https by default.  Everything worked great!

![success](/blog/start/success.jpeg)

## Until...

The power went out in the house and I don't happen to have a UPS for my desktop or modem.  The power eventually came back on, and gitlab came right back up thanks to the power of systemd, but I realized that my site was unavailable for a few hours.  What if someone was looking for my site at that moment looking to give away a million dollars.  I simply can not allow that.  I also noticed when the vm came back online that I had the memory usage set to dynamic and the gitlab vm was eating up 10-12gb of ram regularly, which was way too resource heavy for my liking, considering at this point I was pretty much only using it for a static site.

## Intro Github Actions

I decided to revisit if it was worth trying to self host this site and how much work it would take to build resiliency.  So Github it was.  I already had the site done, so all I really needed to do was translate my gitlab-ci.yml file to a github actions workflow yaml file.  after a little debugging I ended up with the file below, it does a handful of things.

1. the on field dictates that it will begin executing any time there is a push to the master branch
2. When it executes it will run a single job named deploy, what this job does is as follows:
  1. checks out the repo
  2. Installs Hugo Extended
  3. Installs NodeJS and runs an npm install to apply the dependencies in the package.json
  4. Caches the npm dependencies
  5. runs "npm ci" to install the project with a clean slate
  6. runs hugo to build the project, which places the built site in a /public directory, note that the --minify flag just minimizes the final output and removes any unneeded or redundant lines
  7. It deploys it to github pages!

```yaml
name: github pages

on:
  push:
    branches:
      - master  # Set a branch to deploy

jobs:
  deploy:
    runs-on: ubuntu-18.04
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: recursive  # Fetch the theme
          fetch-depth: 0         # Fetch all history for .GitInfo and .Lastmod

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: '0.75.1'
          extended: true

      - name: Setup Node
        uses: actions/setup-node@v1
        with:
          node-version: '12.x'

      - name: Cache dependencies
        uses: actions/cache@v1
        with:
          path: ~/.npm
          key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            ${{ runner.os }}-node-

      - run: npm ci
      - run: hugo --minify

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}

```

## Fin

That's it, the workflow was successful I'm done! that was easy!  Ok, I guess I wasn't done, I had final step and being that this was my first github pages deployment, I did not know that I had to enable it and set a source in the repo settings.  So I went to my repo in Github clicked the settings cog wheel and scrolled down the find the "Github Pages" section.  What that last step in the workflow is actually doing is it's committing the /public directory I mentioned earlier to a branch on the repo named gh-pages.  This branch contains the final deployable product, so I chose that branch as my source, clicked save and Voila! a minute later it showed me a link to my website!

![config](/blog/start/pages-setting.png)


The last thing I did was to rename the repository.  I had the name set to portfolio, which by default will deploy the site to a url like <username>.github.io/<repo-name>, but after renaming my repository to brentgruber.github.io, it deployed directly to that url, so I could safely set the BaseURL in my project to / and it was able to load all of my content.


## What's next

Now that I have a reliable deployment I'd like to start blogging more actively.  I enjoy learning new things and I've always said that you really know something when you can teach it or explain it well.  So that's going to be my goal going forward with this site, is to add more content.  I may have some cleaning up to do on mobile, I know my skills section might need some work, so I can dip my toes into HTML a little bit.  I'd also like to flex the github actions muscles a little more and possibly look into adding some logic so that when I do publish a new blog post it can be automatically added to a dev.to account or posted to my linkedin profile.