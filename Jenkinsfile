pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    APP_NAME = 'papichulo'
    REMOTE_DEPLOY_DIR = '/var/www/papichulo'
    REMOTE_BACKEND_SERVICE = 'papichulo-backend'
    SSH_CRED_ID = 'papichulo-ssh-key'
    REMOTE_HOST_CRED_ID = 'papichulo-remote-host'
    REMOTE_USER_CRED_ID = 'papichulo-remote-user'
    API_BASE_URL_DEV = 'https://dev-api.example.com/api'
    API_BASE_URL_PROD = 'https://api.example.com/api'
  }

  stages {
    stage('Start') {
      steps {
        script {
          echo "Pipeline started for ${env.JOB_NAME} #${env.BUILD_NUMBER}"
          currentBuild.displayName = "#${env.BUILD_NUMBER} - ${env.BRANCH_NAME ?: 'branch-unknown'}"
          currentBuild.description = "Start -> Build -> Deploy -> Success"
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Resolve Environment') {
      steps {
        script {
          def branch = env.BRANCH_NAME ?: (env.GIT_BRANCH ? env.GIT_BRANCH.replaceFirst(/^origin\//, '') : '')
          if (branch == 'main') {
            env.DEPLOY_ENV = 'prod'
            env.BACKEND_ENV_FILE_CRED_ID = 'papichulo-backend-env-prod-file'
            env.FRONTEND_API_BASE_URL = env.API_BASE_URL_PROD
          } else if (branch == 'dev') {
            env.DEPLOY_ENV = 'dev'
            env.BACKEND_ENV_FILE_CRED_ID = 'papichulo-backend-env-dev-file'
            env.FRONTEND_API_BASE_URL = env.API_BASE_URL_DEV
          } else {
            env.DEPLOY_ENV = 'none'
            env.BACKEND_ENV_FILE_CRED_ID = ''
            env.FRONTEND_API_BASE_URL = env.API_BASE_URL_DEV
          }
          echo "Branch=${branch ?: 'unknown'}, deployEnv=${env.DEPLOY_ENV}"
        }
      }
    }

    stage('Backend Build') {
      steps {
        echo 'Building backend...'
        dir('backend') {
          script {
            if (isUnix()) {
              sh 'npm ci'
              sh 'npx prisma generate'
            } else {
              bat 'npm ci'
              bat 'npx prisma generate'
            }
          }
        }
      }
    }

    stage('Frontend Build (Flutter Web)') {
      steps {
        echo 'Building frontend...'
        script {
          if (isUnix()) {
            sh 'flutter pub get'
            sh """
              flutter build web --release \
                --base-href "/Papichulo/" \
                --dart-define=API_BASE_URL=${env.FRONTEND_API_BASE_URL}
            """
          } else {
            bat 'flutter pub get'
            bat "flutter build web --release --base-href \"/Papichulo/\" --dart-define=API_BASE_URL=${env.FRONTEND_API_BASE_URL}"
          }
        }
      }
    }

    stage('Deploy') {
      when {
        expression { (env.DEPLOY_ENV == 'dev' || env.DEPLOY_ENV == 'prod') && isUnix() }
      }
      steps {
        echo "Deploying to ${env.DEPLOY_ENV}..."
        withCredentials([
          file(credentialsId: "${env.BACKEND_ENV_FILE_CRED_ID}", variable: 'BACKEND_ENV_FILE'),
          string(credentialsId: "${env.REMOTE_HOST_CRED_ID}", variable: 'REMOTE_HOST'),
          string(credentialsId: "${env.REMOTE_USER_CRED_ID}", variable: 'REMOTE_USER'),
        ]) {
          sh '''
            cp "$BACKEND_ENV_FILE" backend/.env
            chmod +x scripts/deploy.sh
            DEPLOY_ENV="${DEPLOY_ENV}" \
            REMOTE_HOST="${REMOTE_HOST}" \
            REMOTE_USER="${REMOTE_USER}" \
            REMOTE_DIR="${REMOTE_DEPLOY_DIR}" \
            BACKEND_SERVICE="${REMOTE_BACKEND_SERVICE}" \
            ./scripts/deploy.sh
          '''
        }
      }
    }

    stage('Deploy (Windows Notice)') {
      when {
        expression { (env.DEPLOY_ENV == 'dev' || env.DEPLOY_ENV == 'prod') && !isUnix() }
      }
      steps {
        echo 'Deploy stage skipped: current Jenkins agent is Windows, deploy script expects Unix shell.'
      }
    }

    stage('Success') {
      steps {
        echo 'Build and deployment stages completed successfully.'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'build/web/**,backend/prisma/migrations/**', allowEmptyArchive: true
      cleanWs(deleteDirs: true)
    }
    success {
      echo 'SUCCESS: Pipeline completed.'
    }
    failure {
      echo 'FAILED: Pipeline failed.'
    }
  }
}
