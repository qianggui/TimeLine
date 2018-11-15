gitpulllast:=$(shell git pull 2> /dev/null)

branch:=$(shell git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')

last_tag_on_branch:=$(shell git tag -l "${branch}.*" --sort '*authordate' | tail -1)

len_last_tag:=$(shell echo ${last_tag_on_branch} | awk '{print length $0}')

ifeq (${len_last_tag}, 0)
    last_tag_commit:=""
else
    last_tag_commit:=$(shell git show ${last_tag_on_branch} | grep commit | head -1)
endif

new_commit:=$(shell git log -1 | grep commit)

ifeq (${last_tag_commit}, ${new_commit})
	can_tag:=0
else
	can_tag:=1
endif

tag_prefix:=${branch}.$(shell date +"%y%m%d").
last_tag_of_today:=$(shell git tag | grep "^${tag_prefix}" | tail -n 1 | sed "s/^${tag_prefix}//")

ifneq ("${last_tag_of_today}","")
	tag:=${tag_prefix}$(shell printf "%02d" $(shell echo "${last_tag_of_today} + 1" | bc))
else
	tag:=${tag_prefix}01
endif

.PHONY: tag

tag:
	if test "${can_tag}" == "1" ; then \
        rm -rf ./target ; \
        mvn package ; \
        mv ./target/*.jar ./ ; \
        rm -rf ./target/* ; \
        mv ./*.jar ./target/ ; \
        git add target/* ; \
        git commit -am'create tag' ; \
        git push origin ${branch} ; \
        git tag -a ${tag} -m ${tag} && git push origin ${tag} ; \
	else \
		echo "${last_tag_on_branch}" ; \
	fi