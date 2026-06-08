# Custom commands
de_load_dotenv(){
  if [ -f .env ]; then
    # Open .env, pipe to sed which ignores lines starting with "#", then execute each export
    export $(cat .env | sed 's/#.*//g' | xargs)
  fi
}

de_print_colors(){
  for i in {0..255}
      do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}
  done
}

de_git_commit(){
  mm=""
  branch=""

  if [ $# -eq 2 ]; then
    mm="$1"
    branch="$2"
  elif [ $# -eq 1 ]; then
    mm="main"
    branch="$1"
  else
    echo "Need to supply at least branch name if using main"
  fi

  if [ -n "$branch" ]; then
    git checkout $mm
    git pull
    git checkout $branch
    git rebase $mm

    hash=$(git rev-parse $mm)
    git rebase -i $hash
    echo "Don't forget to push when ready: git push -f origin $branch" 
  fi
}

de_git_work_log(){
  output="de_git_work_log.txt"
  rm -f ~/$output  # Clear the file if it exists

  from="$1" # Date format: YYYY-MM-DD
  to="$2"
  
  start_dir=$(pwd)

  for dir in ~/repos/*/; do
    if [ -d "$dir/.git" ]; then
      repo_name=$(basename "$dir")
      echo "Processing $repo_name"
      cd "$dir"
      echo -e "\n===== $repo_name =====\n" >> ~/$output
      git log --author="jmicalizzi@bbrpartners.com" --since="$from" --until="$to" --pretty=format:"%an | %ad | %s" --date=iso >> ~/$output
      echo -e "" >> ~/$output # Adds a newline
    fi
  done

  # Also do ~/.dotfiles
  cd ~/.dotfiles
  echo -e "\n===== dotfiles =====\n" >> ~/$output
  git log --author="jmicalizzi@bbrpartners.com" --since="$from" --until="$to" --pretty=format:"%an | %ad | %s" --date=iso >> ~/$output
  echo -e "" >> ~/$output # Adds a newline

  cd "$start_dir"
}

alias de_pyact='source .venv/bin/activate'
alias de_pydeact='deactivate'
alias de_tfp='terraform plan -out=$HOME/tfplan && terraform show -json $HOME/tfplan > $HOME/tfplan.json'
