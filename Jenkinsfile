// Repository name use, must end with / or be '' for none
repository= 'area51/'

// image prefix
imagePrefix = 'postgres'

// The versions to build. Latest is first.
// 9.6 is legacy but still in use
versions=[ '10', '9', '9.6' ]

// The architectures to build, in format recognised by docker
architectures = [ 'amd64', 'arm64v8' ]

// The slave label based on architecture
def slaveId = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'AMD64'
    case 'arm64v8':
      return 'ARM64'
    default:
      return 'amd64'
  }
}

// The docker image name
// architecture can be '' for multiarch images
def dockerImage = {
  architecture, version -> repository + imagePrefix + ':' +
    ( architecture=='' ? '' : ( architecture + '-' ) ) +
    version
}

// The go arch
def goarch = {
  architecture -> switch( architecture ) {
    case 'amd64':
      return 'amd64'
    case 'arm32v6':
    case 'arm32v7':
      return 'arm'
    case 'arm64v8':
      return 'arm64'
    default:
      return architecture
  }
}

properties( [
  buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '7', numToKeepStr: '10')),
  disableConcurrentBuilds(),
  disableResume(),
  pipelineTriggers([
    cron('H H * * *'),
  ])
])

def build = {
  architecture, version -> node( slaveId( architecture ) ) {
    stage( 'Prepare ' + architecture + ' ' + version ) {
      checkout scm
      sh 'docker pull postgres:' + version
    }

    stage( 'Build' + architecture + ' ' + version ) {
      sh 'docker build -t ' + dockerImage( architecture, version ) + ' --build-arg POSTGRES_VERSION=' + version + ' .'
    }

    stage( 'Publish ' + architecture + ' ' + version ) {
      sh 'docker push ' + dockerImage( architecture, version )
    }
  }
}

versions.each {
  version -> stage( version ) {
    parallel(
      'amd64': { build( 'amd64',version ) },
      'arm64v8': { build( 'arm64v8', version ) }
    )
}

versions.each {
    node( 'AMD64' ) {
      stage( 'publish ' + architecture ) {

        // Create/amend the manifest with our architectures
        manifests = architectures.collect { architecture -> dockerImage( architecture, version ) }
        sh 'docker manifest create -a ' + dockerImage( '', version ) + ' ' + manifests.join(' ')

        // For each architecture annotate them to be correct
        architectures.each {
          architecture -> sh 'docker manifest annotate' +
            ' --os linux' +
            ' --arch ' + goarch( architecture ) +
            ' ' + dockerImage( '', version ) +
            ' ' + dockerImage( architecture, version )
        }

        // Publish the manifest
        sh 'docker manifest push -p ' + dockerImage( '', version )
      }
    }
  }
}
